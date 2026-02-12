#!/usr/bin/env python3
"""
Secret Guard - Claude Code PreToolUse Hook for Secret File Protection

This script prevents Claude Code from accessing sensitive files containing
secrets, credentials, API keys, and other confidential information.

Features:
- Blocks access to common secret file patterns (.env, credentials, etc.)
- Parses Bash commands to detect file access attempts
- Supports custom configuration via JSON/YAML config file
- Provides clear denial messages to Claude
- Optional logging of blocked attempts

Usage:
    This script is invoked by Claude Code as a PreToolUse hook.
    Configure it in ~/.claude/settings.json under the "hooks" section.

Author: Created for Doctor terakoya
License: MIT
"""

from __future__ import annotations

import fnmatch
import json
import logging
import os
import re
import shlex
import sys
from dataclasses import dataclass, field
from pathlib import Path, PurePath
from typing import Any, Callable, Optional

# Optional YAML support
try:
    import yaml

    YAML_AVAILABLE = True
except ImportError:
    YAML_AVAILABLE = False


# ============================================================================
# Constants
# ============================================================================

DEFAULT_SENSITIVE_PATTERNS: list[str] = [
    # Environment files
    ".env",
    ".env.*",
    ".env-*",
    "*.env",
    ".envrc",
    # Credential files
    "credentials",
    "credentials.*",
    "*.credentials",
    # Secret files
    "secrets",
    "secrets.*",
    "*.secret",
    "*.secrets",
    # AWS
    ".aws/credentials",
    ".aws/config",
    # SSH keys (private keys only)
    ".ssh/id_*",
    ".ssh/config",
    # mise
    "mise.local.toml",
    # Key files
    "*.pem",
    "*.key",
    "*.p12",
    "*.pfx",
    # Auth tokens
    ".netrc",
    ".npmrc",
    ".pypirc",
    ".docker/config.json",
    ".gitcredentials",
    ".git-credentials",
    # Kubernetes
    "kubeconfig",
    ".kube/config",
    # Terraform
    "*.tfvars",
    "*.auto.tfvars",
    "*.tfstate",
    "*.tfstate.*",
    # Ansible Vault
    "vault.yml",
    "vault.yaml",
    "*vault*.yml",
    "*vault*.yaml",
    # Other
    ".htpasswd",
    "master.key",
    "*.oath",
]

DEFAULT_ALLOWED_EXCEPTIONS: list[str] = [
    # Example/template files are okay
    ".env.example",
    ".env.sample",
    ".env.template",
    "example.env",
    "sample.env",
    "template.env",
    # Public keys are okay
    "*.pub",
    "*.pubkey",
    "id_*.pub",
]

DEFAULT_SENSITIVE_REGEX: list[str] = [
    # SSH private keys with absolute paths
    r".*[/\\]\.?ssh[/\\]id_(rsa|ed25519|ecdsa|dsa)$",
    # Files with secret in the name followed by config extensions
    r".*[/\\]\.?.*secret.*\.(json|yaml|yml|toml)$",
]

DEFAULT_FILE_READING_COMMANDS: frozenset[str] = frozenset(
    {
        "cat",
        "head",
        "tail",
        "less",
        "more",
        "vim",
        "vi",
        "nano",
        "emacs",
        "grep",
        "egrep",
        "fgrep",
        "rg",
        "awk",
        "sed",
        "source",
        ".",
        "tee",
        "cp",
        "mv",
        "scp",
        "rsync",
        "bat",
        "view",
        "pg",
    }
)

# Regex patterns for sensitive file detection in commands
SENSITIVE_COMMAND_PATTERNS: list[str] = [
    r"(?:^|[\s\"\'/\\])(credentials(?:\.[a-zA-Z0-9_-]+)?)",
    r"(?:^|[\s\"\'/\\])(secrets(?:\.[a-zA-Z0-9_-]+)?)",
    r"(?:^|[\s\"\'/\\])([a-zA-Z0-9_-]*\.(?:pem|key|p12|pfx))\b",
    r"(?:^|[\s\"\'/\\])(\.aws/[a-zA-Z0-9_-]+)",
    r"(?:^|[\s\"\'/\\])(\.ssh/[a-zA-Z0-9_-]+)",
    r"(?:^|[\s\"\'/\\])(kubeconfig)",
    r"(?:^|[\s\"\'/\\])(\.kube/config)",
    r"(?:^|[\s\"\'/\\])([a-zA-Z0-9_-]*\.tfvars)",
    r"(?:^|[\s\"\'/\\])([a-zA-Z0-9_-]*\.tfstate)",
]


# ============================================================================
# Configuration
# ============================================================================


@dataclass
class Config:
    """Configuration for the secret protection hook."""

    sensitive_patterns: list[str] = field(default_factory=list)
    allowed_exceptions: list[str] = field(default_factory=list)
    sensitive_regex: list[str] = field(default_factory=list)
    file_reading_commands: frozenset[str] = field(default_factory=frozenset)
    logging_enabled: bool = False
    log_file: Optional[str] = None
    log_blocked: bool = True
    check_symlinks: bool = True
    case_insensitive: bool = False


def get_default_config() -> Config:
    """Return the default configuration with common sensitive file patterns."""
    return Config(
        sensitive_patterns=DEFAULT_SENSITIVE_PATTERNS.copy(),
        allowed_exceptions=DEFAULT_ALLOWED_EXCEPTIONS.copy(),
        sensitive_regex=DEFAULT_SENSITIVE_REGEX.copy(),
        file_reading_commands=DEFAULT_FILE_READING_COMMANDS,
        logging_enabled=False,
        log_file=os.path.expanduser("~/.claude/hooks/secret_guard.log"),
        log_blocked=True,
        check_symlinks=True,
        case_insensitive=False,
    )


def _get_config_paths() -> list[Path]:
    """Get list of config file paths to search, handling missing HOME gracefully."""
    try:
        home = Path.home()
    except RuntimeError:
        return []
    base = home / ".claude" / "hooks"
    return [
        base / "secret_guard.json",
        base / "secret_guard.yaml",
        base / "secret_guard.yml",
    ]


def load_config_file() -> Optional[dict[str, Any]]:
    """Load configuration from JSON or YAML file if available."""
    for config_path in _get_config_paths():
        if not config_path.exists():
            continue
        try:
            with open(config_path, encoding="utf-8") as f:
                if config_path.suffix in (".yaml", ".yml"):
                    if YAML_AVAILABLE:
                        return yaml.safe_load(f)
                    logging.warning(
                        "YAML config found but PyYAML not installed: %s", config_path
                    )
                elif config_path.suffix == ".json":
                    return json.load(f)
        except (OSError, json.JSONDecodeError) as e:
            logging.warning("Failed to load config from %s: %s", config_path, e)
            continue
        except Exception as e:
            # Catches yaml.YAMLError when PyYAML is installed,
            # and any other unexpected parse errors
            if YAML_AVAILABLE and isinstance(e, yaml.YAMLError):
                logging.warning("Failed to parse YAML config %s: %s", config_path, e)
            else:
                logging.warning("Unexpected error loading config %s: %s", config_path, e)
            continue
    return None


def merge_config(base: Config, override: dict[str, Any]) -> Config:
    """Merge file-based config overrides into base config."""
    if "sensitive_patterns" in override:
        base.sensitive_patterns = override["sensitive_patterns"]
    if "allowed_exceptions" in override:
        base.allowed_exceptions = override["allowed_exceptions"]
    if "sensitive_regex" in override:
        base.sensitive_regex = override["sensitive_regex"]
    if "file_reading_commands" in override:
        base.file_reading_commands = frozenset(override["file_reading_commands"])
    if "logging_enabled" in override:
        base.logging_enabled = override["logging_enabled"]
    if "log_file" in override:
        base.log_file = override["log_file"]
    if "log_blocked" in override:
        base.log_blocked = override["log_blocked"]
    if "check_symlinks" in override:
        base.check_symlinks = override["check_symlinks"]
    if "case_insensitive" in override:
        base.case_insensitive = override["case_insensitive"]

    # Support additive patterns
    if "additional_sensitive_patterns" in override:
        base.sensitive_patterns.extend(override["additional_sensitive_patterns"])
    if "additional_allowed_exceptions" in override:
        base.allowed_exceptions.extend(override["additional_allowed_exceptions"])
    if "additional_sensitive_regex" in override:
        base.sensitive_regex.extend(override["additional_sensitive_regex"])

    return base


def get_config() -> Config:
    """Get configuration, merging file config with defaults."""
    config = get_default_config()
    file_config = load_config_file()
    if file_config:
        config = merge_config(config, file_config)
    return config


# ============================================================================
# Path Matching
# ============================================================================


def normalize_path(path: str, cwd: str) -> str:
    """Normalize a file path for consistent matching.

    Args:
        path: The file path to normalize
        cwd: Current working directory

    Returns:
        Normalized absolute path
    """
    if not path:
        return ""

    # Expand user home directory
    path = os.path.expanduser(path)

    # Make absolute if relative
    if not os.path.isabs(path):
        path = os.path.join(cwd, path)

    # Normalize the path (resolve .. and .)
    return os.path.normpath(path)


def resolve_symlinks(path: str) -> str:
    """Resolve symlinks in path to get the real path.

    Args:
        path: The file path to resolve

    Returns:
        Resolved path or original if resolution fails
    """
    try:
        resolved = Path(path).resolve()
        return str(resolved)
    except (OSError, ValueError):
        # File doesn't exist or can't be resolved
        return path


def matches_pattern(path: str, pattern: str, case_insensitive: bool = False) -> bool:
    """Check if a path matches a glob pattern.

    Args:
        path: The file path to check
        pattern: The glob pattern to match against
        case_insensitive: Whether to perform case-insensitive matching

    Returns:
        True if the path matches the pattern
    """
    if case_insensitive:
        path = path.lower()
        pattern = pattern.lower()

    basename = os.path.basename(path)

    # Try matching against basename
    if fnmatch.fnmatch(basename, pattern):
        return True

    # Try matching against full path using fnmatch
    if fnmatch.fnmatch(path, pattern):
        return True

    # Use pathlib.PurePath.match for proper ** glob support
    try:
        path_obj = PurePath(path)
        if path_obj.match(pattern):
            return True
    except (ValueError, TypeError):
        pass

    # Try matching the pattern against any suffix of the path
    # This handles patterns like ".aws/credentials" matching "/home/user/.aws/credentials"
    path_parts = path.replace("\\", "/").split("/")
    pattern_parts = pattern.replace("\\", "/").split("/")

    if len(pattern_parts) > 1:
        # Multi-part pattern, try suffix matching
        for i in range(len(path_parts) - len(pattern_parts) + 1):
            suffix = "/".join(path_parts[i:])
            if fnmatch.fnmatch(suffix, pattern):
                return True

    return False


def _check_path_against_patterns(
    path: str, config: Config
) -> Optional[bool]:
    """Check a single path against patterns.

    Args:
        path: The normalized path to check
        config: Configuration object

    Returns:
        True if sensitive, False if explicitly allowed, None if no match
    """
    basename = os.path.basename(path)

    # Check against allowed exceptions first
    for exception in config.allowed_exceptions:
        if matches_pattern(path, exception, config.case_insensitive):
            return False
        if matches_pattern(basename, exception, config.case_insensitive):
            return False

    # Check glob patterns
    for pattern in config.sensitive_patterns:
        if matches_pattern(path, pattern, config.case_insensitive):
            return True
        if matches_pattern(basename, pattern, config.case_insensitive):
            return True

    # Check regex patterns
    for regex in config.sensitive_regex:
        try:
            flags = re.IGNORECASE if config.case_insensitive else 0
            if re.search(regex, path, flags):
                return True
        except re.error as e:
            logging.warning("Invalid regex pattern '%s': %s", regex, e)
            continue

    return None


def is_sensitive_path(path: str, cwd: str, config: Config) -> bool:
    """Check if a path matches sensitive file patterns.

    Checks both the original path AND the resolved symlink target to prevent
    bypasses where a sensitive filename points to a non-sensitive target or
    vice versa.

    Args:
        path: The file path to check
        cwd: Current working directory
        config: Configuration object

    Returns:
        True if the path is considered sensitive
    """
    if not path:
        return False

    # Normalize the path
    normalized = normalize_path(path, cwd)

    # Build list of paths to check (original + resolved symlink if different)
    paths_to_check = [normalized]
    if config.check_symlinks:
        resolved = resolve_symlinks(normalized)
        if resolved != normalized:
            paths_to_check.append(resolved)

    # Check all paths - if ANY is sensitive, block; but allow only if ALL are allowed
    any_sensitive = False
    all_explicitly_allowed = True

    for check_path in paths_to_check:
        result = _check_path_against_patterns(check_path, config)
        if result is True:
            any_sensitive = True
        if result is not False:
            all_explicitly_allowed = False

    # If any path is sensitive, block (unless explicitly allowed)
    if any_sensitive and not all_explicitly_allowed:
        return True

    return False


# ============================================================================
# Bash Command Parsing
# ============================================================================


def _tokenize_command(command: str) -> list[list[str]]:
    """Split command by pipes and tokenize each segment.

    Args:
        command: The full bash command string

    Returns:
        List of token lists, one per pipe segment
    """
    segments: list[list[str]] = []
    command_parts = command.split("|")

    for part in command_parts:
        part = part.strip()
        if not part:
            continue
        try:
            tokens = shlex.split(part)
        except ValueError:
            # If shlex fails, fall back to simple split
            tokens = part.split()
        if tokens:
            segments.append(tokens)

    return segments


def _extract_paths_from_tokens(
    tokens: list[str], file_reading_commands: frozenset[str]
) -> set[str]:
    """Extract file paths from tokenized command arguments.

    Args:
        tokens: List of command tokens
        file_reading_commands: Set of commands that read files

    Returns:
        Set of potential file paths
    """
    paths: set[str] = set()
    i = 0

    while i < len(tokens):
        token = tokens[i]
        # Remove leading ./ prefix (but not arbitrary combinations of . and /)
        clean_token = token[2:] if token.startswith("./") else token

        # Check if this is a file-reading command
        if clean_token in file_reading_commands or token in file_reading_commands:
            # Next tokens could be options or file paths
            j = i + 1
            while j < len(tokens):
                arg = tokens[j]
                if arg.startswith("-"):
                    # Skip option flags; some options take values
                    if arg in ["-c", "-f", "-e", "-F", "-n", "-o", "-i", "-r", "-w", "-a"]:
                        j += 1  # Skip the option value too
                    j += 1
                    continue
                # Skip if it looks like a regex pattern
                if not (
                    arg.startswith("^")
                    or arg.startswith("(")
                    or (arg.startswith("[") and "/" not in arg)
                ):
                    paths.add(arg)
                j += 1
        i += 1

    return paths


def _find_sensitive_patterns_in_command(command: str) -> set[str]:
    """Use regex to find known sensitive file patterns in raw command.

    Args:
        command: The raw command string

    Returns:
        Set of potential sensitive file paths
    """
    paths: set[str] = set()

    # Look for .env files
    env_pattern = r"(?:^|[\s\"\'/\\])(\.[eE][nN][vV](?:\.[a-zA-Z0-9_-]+)?)\b"
    for match in re.finditer(env_pattern, command):
        paths.add(match.group(1))

    # Look for other sensitive patterns
    for pattern in SENSITIVE_COMMAND_PATTERNS:
        for match in re.finditer(pattern, command, re.IGNORECASE):
            paths.add(match.group(1))

    return paths


def _extract_redirection_targets(command: str) -> set[str]:
    """Extract file paths from shell redirections.

    Args:
        command: The raw command string

    Returns:
        Set of redirection target paths
    """
    paths: set[str] = set()
    redirect_pattern = r"(?:>|>>)\s*([^\s|&;]+)"

    for match in re.finditer(redirect_pattern, command):
        path = match.group(1).strip("\"'")
        paths.add(path)

    return paths


def extract_paths_from_command(command: str, config: Config) -> list[str]:
    """Extract potential file paths from a Bash command.

    This function uses multiple strategies to detect file paths:
    1. Tokenization with shlex and command-aware path extraction
    2. Pattern matching for sensitive file names in the command string
    3. Redirection target extraction

    Args:
        command: The Bash command to parse
        config: Configuration object

    Returns:
        List of potential file paths found in the command
    """
    if not command:
        return []

    paths: set[str] = set()

    # Strategy 1: Token-based extraction
    try:
        for segment in _tokenize_command(command):
            paths.update(
                _extract_paths_from_tokens(segment, config.file_reading_commands)
            )
    except Exception as e:
        # Log but continue with other strategies
        logging.debug("Token-based extraction failed for command: %s", e)

    # Strategy 2: Pattern matching for sensitive file patterns
    paths.update(_find_sensitive_patterns_in_command(command))

    # Strategy 3: Redirection targets
    paths.update(_extract_redirection_targets(command))

    return list(paths)


# ============================================================================
# Tool Handlers
# ============================================================================

ToolHandler = Callable[[dict[str, Any], str, Config], Optional[str]]


def create_path_checker(param_name: str) -> ToolHandler:
    """Factory function to create path-checking handlers.

    Args:
        param_name: The parameter name that contains the file path

    Returns:
        A handler function that checks if the path is sensitive
    """

    def checker(
        tool_input: dict[str, Any], cwd: str, config: Config
    ) -> Optional[str]:
        file_path = tool_input.get(param_name, "")
        if is_sensitive_path(file_path, cwd, config):
            return f"Access denied: '{file_path}' matches sensitive file pattern"
        return None

    return checker


def check_bash_tool(
    tool_input: dict[str, Any], cwd: str, config: Config
) -> Optional[str]:
    """Check if Bash command accesses sensitive files.

    Args:
        tool_input: The tool input containing the command
        cwd: Current working directory
        config: Configuration object

    Returns:
        Reason string if blocked, None if allowed
    """
    command = tool_input.get("command", "")
    paths = extract_paths_from_command(command, config)

    for path in paths:
        if is_sensitive_path(path, cwd, config):
            return (
                f"Access denied: command appears to access '{path}' "
                "which matches sensitive file pattern"
            )

    return None


# Map of tool names to their handler functions
TOOL_HANDLERS: dict[str, ToolHandler] = {
    # Standard Claude Code tools
    "Read": create_path_checker("file_path"),
    "Write": create_path_checker("file_path"),
    "Edit": create_path_checker("file_path"),
    "Bash": check_bash_tool,
    "Grep": create_path_checker("path"),
    # Serena MCP tools
    "mcp__serena__read_file": create_path_checker("relative_path"),
    "mcp__serena__search_for_pattern": create_path_checker("relative_path"),
    "mcp__serena__find_file": create_path_checker("relative_path"),
    "mcp__serena__list_dir": create_path_checker("relative_path"),
}


def check_tool_input(
    tool_name: str, tool_input: dict[str, Any], cwd: str, config: Config
) -> Optional[str]:
    """Check if a tool call should be blocked.

    Args:
        tool_name: Name of the tool being called
        tool_input: Input parameters for the tool
        cwd: Current working directory
        config: Configuration object

    Returns:
        Reason string if blocked, None if allowed
    """
    handler = TOOL_HANDLERS.get(tool_name)
    if handler:
        return handler(tool_input, cwd, config)
    return None


# ============================================================================
# Logging
# ============================================================================


def setup_logging(config: Config) -> None:
    """Set up logging based on configuration.

    Args:
        config: Configuration object
    """
    if not config.logging_enabled:
        return

    log_file = config.log_file
    if log_file:
        log_file = os.path.expanduser(log_file)
        log_dir = os.path.dirname(log_file)
        if log_dir and not os.path.exists(log_dir):
            os.makedirs(log_dir, exist_ok=True)

        logging.basicConfig(
            filename=log_file,
            level=logging.INFO,
            format="%(asctime)s - %(levelname)s - %(message)s",
        )


def log_blocked(
    tool_name: str, tool_input: dict[str, Any], reason: str, config: Config
) -> None:
    """Log a blocked tool call.

    Args:
        tool_name: Name of the blocked tool
        tool_input: Input parameters that were blocked
        reason: Reason for blocking
        config: Configuration object
    """
    if config.logging_enabled and config.log_blocked:
        # Use shlex.quote-like escaping for safety in log output
        safe_input = json.dumps(tool_input)
        logging.warning("BLOCKED: %s - %s - Input: %s", tool_name, reason, safe_input)


# ============================================================================
# Main Hook Function
# ============================================================================


def main() -> None:
    """Main hook execution function.

    Reads JSON input from stdin, checks if the tool access should be blocked,
    and outputs the appropriate response.
    """
    # Read input from stdin
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError as e:
        print(f"Invalid JSON input: {e}", file=sys.stderr)
        sys.exit(2)

    # Load configuration
    config = get_config()

    # Set up logging
    setup_logging(config)

    # Extract tool information
    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})
    cwd = input_data.get("cwd", os.getcwd())

    # Check if the tool access should be blocked
    block_reason = check_tool_input(tool_name, tool_input, cwd, config)

    if block_reason:
        # Log the blocked attempt
        log_blocked(tool_name, tool_input, block_reason, config)

        # Output deny response
        output = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": block_reason,
            }
        }
        print(json.dumps(output))

    # Exit successfully (exit code 0 is required for JSON output to be processed)
    sys.exit(0)


if __name__ == "__main__":
    main()

# Import Statement Conventions

## Import Order Rules

Organize import statements in the following order, with each group separated by a single blank line:

### 1. Third-party packages
External libraries installed via npm, pip, cargo, etc.

### 2. Internal/Absolute imports
Modules from within the repository using absolute paths (e.g., `@/`, `~/`, or project-defined aliases)

### 3. Relative imports
Local files in the same or nearby directories using relative paths (e.g., `./`, `../`)

## Sorting Rules

- Within each group, sort imports **alphabetically** by module/package name
- Sort is case-insensitive

## Example (TypeScript/JavaScript)

```typescript
// 1. Third-party packages (alphabetical)
import axios from 'axios';
import { useEffect, useState } from 'react';
import { z } from 'zod';

// 2. Internal/Absolute imports (alphabetical)
import { apiClient } from '@/lib/api';
import { Button } from '@/components/ui/button';
import { useAuth } from '@/hooks/useAuth';

// 3. Relative imports (alphabetical)
import { formatDate } from './utils';
import type { UserProps } from './types';
```

## Example (Python)

```python
# 1. Third-party packages (alphabetical)
import numpy as np
import pandas as pd
from fastapi import FastAPI

# 2. Internal/Absolute imports (alphabetical)
from app.config import settings
from app.models.user import User
from app.services.auth import AuthService

# 3. Relative imports (alphabetical)
from .helpers import format_response
from .schemas import UserSchema
```

## Notes

- Always apply this ordering when writing new code or refactoring existing imports
- When reviewing code, suggest corrections if imports don't follow this convention

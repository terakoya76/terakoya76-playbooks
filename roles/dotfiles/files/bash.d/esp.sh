# espup writes the PATH and LIBCLANG_PATH the Xtensa toolchain needs here rather than into
# the shell rc. Guarded because only hosts that ran the esp32 role have it.
if [ -f "$HOME/export-esp.sh" ]; then
  . "$HOME/export-esp.sh"
fi

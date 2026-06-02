"""
Re-exports `sh` utilities from `//@star/prelude/exec/sh.star`.
"""

load(
    "//@star/prelude/exec/sh.star",
    "sh_run",  # @unused
    "sh_capture",  # @unused
    "sh_lines",  # @unused
    "sh_exit_code",  # @unused
    "sh_pipe",  # @unused
)

"""
Re-exports `process` utilities from `//@star/prelude/exec/process.star`.
"""

load(
    "//@star/prelude/exec/process.star",
    "process_stdout_inherit",  # @unused
    "process_stdout_capture",  # @unused
    "process_stdout_null",  # @unused
    "process_stdout_file",  # @unused
    "process_stderr_inherit",  # @unused
    "process_stderr_capture",  # @unused
    "process_stderr_null",  # @unused
    "process_stderr_merge",  # @unused
    "process_stderr_file",  # @unused
    "process_options",  # @unused
    "process_run",  # @unused
    "process_capture",  # @unused
    "process_spawn",  # @unused
    "process_is_running",  # @unused
    "process_kill",  # @unused
    "process_wait",  # @unused
    "process_pipeline",  # @unused
)

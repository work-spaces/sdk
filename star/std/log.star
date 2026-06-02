"""
Re-exports `log` utilities from `//@star/prelude/exec/log.star`.
"""

load(
    "//@star/prelude/exec/log.star",
    "log_set_level",  # @unused
    "log_trace",  # @unused
    "log_set_format",  # @unused
    "log_debug",  # @unused
    "log_info",  # @unused
    "log_warn",  # @unused
    "log_error",  # @unused
    "log_fatal",  # @unused
)

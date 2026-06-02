"""
Info helpers re-exported from the prelude.

This module provides a stable SDK import surface for
`//@star/prelude/info.star`.
"""

load(
    "//@star/prelude/info.star",
    "info_get_cpu_count",  # @unused
    "info_get_execution_phase",  # @unused
    "info_get_path_to_spaces_tools",  # @unused
    "info_get_path_to_store",  # @unused
    "info_get_platform_name",  # @unused
    "info_get_supported_platforms",  # @unused
    "info_is_ci",  # @unused
    "info_is_execution_phase_checkout",  # @unused
    "info_is_execution_phase_inspect",  # @unused
    "info_is_execution_phase_run",  # @unused
    "info_is_platform_aarch64",  # @unused
    "info_is_platform_linux",  # @unused
    "info_is_platform_macos",  # @unused
    "info_is_platform_windows",  # @unused
    "info_is_platform_x86_64",  # @unused
    "info_parse_log_file",  # @unused
    "info_set_max_queue_count",  # @unused
    "info_set_minimum_version",  # @unused
    "info_set_required_semver",  # @unused
)

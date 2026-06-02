"""
Workspace helpers re-exported from the rules prelude.

This module provides a stable SDK import surface for
`//@star/prelude/rules/ws.star`.
"""

load(
    "//@star/prelude/rules/ws.star",
    "WORKSPACE_SYSROOT",  # @unused
    "workspace_assert_member_revision",  # @unused
    "workspace_assert_member_semver",  # @unused
    "workspace_check_member_revision",  # @unused
    "workspace_check_member_semver",  # @unused
    "workspace_get_absolute_path",  # @unused
    "workspace_get_build_archive_info",  # @unused
    "workspace_get_cpu_count",  # @unused
    "workspace_get_env_var",  # @unused
    "workspace_get_env_var_or",  # @unused
    "workspace_get_env_var_or_none",  # @unused
    "workspace_get_path_to_checkout",  # @unused
    "workspace_get_path_to_home",  # @unused
    "workspace_get_path_to_log_file",  # @unused
    "workspace_get_path_to_member",  # @unused
    "workspace_get_path_to_member_or_none",  # @unused
    "workspace_get_path_to_member_with_rev",  # @unused
    "workspace_get_path_to_member_with_semver",  # @unused
    "workspace_is_env_var_set",  # @unused
    "workspace_is_env_var_set_to",  # @unused
    "workspace_is_path_to_member_available",  # @unused
    "workspace_is_reproducible",  # @unused
    "workspace_load_value",  # @unused
    "workspace_load_value_or",  # @unused
    "workspace_set_always_evaluate",  # @unused
)

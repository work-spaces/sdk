"""
Checkout helpers re-exported from the rules prelude.

This module re-exports most helpers from `//@star/prelude/rules/checkout.star`
and keeps a subset of SDK-local wrappers for backward compatibility.
"""

load(
    "//@star/prelude/rules/checkout.star",
    "checkout_add_any_assets",  # @unused
    "checkout_add_archive",  # @unused
    "checkout_add_env_vars",  # @unused
    "checkout_add_exec",  # @unused
    "checkout_add_home_assets",  # @unused
    "checkout_add_home_store_env",  # @unused
    "checkout_add_oras_archive",  # @unused
    "checkout_add_platform_archive",  # @unused
    "checkout_add_repo",  # @unused
    "checkout_clone_blobless",  # @unused
    "checkout_clone_default",  # @unused
    "checkout_clone_shallow",  # @unused
    "checkout_clone_worktree",  # @unused
    "checkout_get_compile_commands_spaces_name",  # @unused
    "checkout_sparse_mode_cone",  # @unused
    "checkout_sparse_mode_no_cone",  # @unused
    "checkout_store_value",  # @unused
    "checkout_type_default",  # @unused
    "checkout_type_optional",  # @unused
    "checkout_update_asset",  # @unused
    "checkout_update_shell",  # @unused
    "checkout_update_shell_shortcuts",  # @unused
    "checkout_update_shell_startup",  # @unused
)
load("info.star", "info_set_minimum_version", "info_set_required_semver")

def checkout_add_asset(
        name: str,
        content: str,
        destination: str,
        deps: list[str] = [],
        type: str | None = None,
        platforms: list[str] | None = None,
        visibility: str | dict[str, list[str]] | None = None):
    """
    Adds an asset to the workspace.

    This will create a file in the workspace with the given content as string value.

    Args:
        name: The name of the rule.
        content: The content of the file to create.
        destination: The destination path for the file.
        deps: List of dependencies for the rule.
        type: use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        platforms: List of [platforms](/docs/builtins/#rule-options) to add the archive to.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.
    """
    if visibility != None:
        info_set_minimum_version("0.15.24")
    EFFECTIVE_VISIBILITY = {"visibility": visibility} if visibility != None else {}

    checkout.add_asset(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        } | EFFECTIVE_VISIBILITY,
        asset = {
            "content": content,
            "destination": destination,
        },
    )

def checkout_add_cargo_bin(
        name: str,
        crate: str,
        version: str,
        bins: list[str],
        deps: list[str] = [],
        type: str | None = None,
        platforms: list[str] | None = None,
        visibility: str | dict[str, list[str]] | None = None):
    """
    Adds a cargo binary to the workspace.

    Args:
        name: The name of the rule.
        crate: The name of the crate.
        version: The version of the crate.
        bins: List of binaries to add.
        deps: List of dependencies for the rule.
        type: use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        platforms: List of [platforms](/docs/builtins/#rule-options) to add the archive to.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.
    """
    if visibility != None:
        info_set_minimum_version("0.15.24")
    EFFECTIVE_VISIBILITY = {"visibility": visibility} if visibility != None else {}

    checkout.add_cargo_bin(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        } | EFFECTIVE_VISIBILITY,
        cargo_bin = {
            "crate": crate,
            "version": version,
            "bins": bins,
        },
    )

def checkout_add_hard_link_asset(
        name: str,
        source: str,
        destination: str,
        deps: list[str] = [],
        type: str | None = None,
        platforms: list[str] | None = None,
        visibility: str | dict[str, list[str]] | None = None):
    """
    Adds a hard link asset to the workspace.

    Args:
        name: The name of the rule.
        source: The source path of the asset.
        destination: The destination path for the asset.
        deps: List of dependencies for the asset.
        type: use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        platforms: List of [platforms](/docs/builtins/#rule-options) to add the archive to.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.
    """
    if visibility != None:
        info_set_minimum_version("0.15.24")
    EFFECTIVE_VISIBILITY = {"visibility": visibility} if visibility != None else {}

    checkout.add_hard_link_asset(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        } | EFFECTIVE_VISIBILITY,
        asset = {
            "source": source,
            "destination": destination,
        },
    )

def checkout_add_soft_link_asset(
        name: str,
        source: str,
        destination: str,
        deps: list[str] = [],
        type: str | None = None,
        platforms: list[str] | None = None,
        visibility: str | dict[str, list[str]] | None = None):
    """
    Adds a soft link asset to the workspace.

    Args:
        name: The name of the rule.
        source: The source path of the soft link.
        destination: The relative workspace path of the soft link destination.
        deps: List of dependencies for the asset.
        type: use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        platforms: List of [platforms](/docs/builtins/#rule-options) to add the archive to.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.
    """
    if visibility != None:
        info_set_minimum_version("0.15.24")
    EFFECTIVE_VISIBILITY = {"visibility": visibility} if visibility != None else {}

    checkout.add_soft_link_asset(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        } | EFFECTIVE_VISIBILITY,
        asset = {
            "source": source,
            "destination": destination,
        },
    )

def checkout_add_target(
        name: str,
        deps: list[str],
        type: str | None = None,
        platforms: list[str] | None = None,
        visibility: str | dict[str, list[str]] | None = None):
    """
    Adds a target to the workspace.

    Args:
        name: The name of the rule.
        deps: List of dependencies for the target.
        type: use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        platforms: List of [platforms](/docs/builtins/#rule-options) to add the archive to.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.
    """
    if visibility != None:
        info_set_minimum_version("0.15.24")
    EFFECTIVE_VISIBILITY = {"visibility": visibility} if visibility != None else {}

    checkout.add_target(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        } | EFFECTIVE_VISIBILITY,
    )

def checkout_update_env(
        name: str,
        vars: dict = {},
        paths: list[str] = [],
        system_paths: list[str] | None = None,
        inherited_vars: list[str] | None = None,
        optional_inherited_vars: list[str] | None = None,
        run_inherited_vars: list[str] | None = None,
        secret_inherited_vars: list[str] | None = None,
        deps: list[str] = [],
        type: str | None = None,
        platforms: list[str] | None = None,
        visibility: str | dict[str, list[str]] | None = None):
    """
    Updates the environment with the given variables and paths.

    Variables other than PATH are added as key/value pairs. PATH is added as a list of values. The order
    of the PATHS is based on execution order which can be controlled using `deps`. The `system_paths`
    are added after the `paths` values.

    All vars are fixed at checkout time except vars specified in `run_inherited_vars`. Checkout vars
    are stored in the new workspace in `env.spaces.star`. `run_inherited_vars` are inherited when executing `spaces run`.
    `secret_inherited_vars` are inherited when executing spaces checkout or run. The values of the secrets are masked in the logs and terminal.

    Args:
        name: The name of the rule.
        vars: Dictionary of variables to store in `env.spaces.star`.
        paths: List of paths to add to the PATH.
        system_paths: The path to add to the system PATH.
        inherited_vars: List of variables to inherit from the calling environment and store in `env.spaces.star`.
        optional_inherited_vars: List of variables to inherit from the calling environment if they exist and store in `env.spaces.star` (requires spaces >v0.15.1)
        run_inherited_vars: List of variables inherited when executing spaces run.
        secret_inherited_vars: List of variables inherited when executing spaces checkout/run. Values will be masked in the logs and terminal.
        deps: List of dependencies for the rule.
        type: use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        platforms: List of [platforms](/docs/builtins/#rule-options) to add the archive to.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.
    """

    if optional_inherited_vars != None:
        info_set_required_semver(">=0.15.17")

    if run_inherited_vars != None:
        info_set_required_semver(">=0.15.17")

    if secret_inherited_vars != None:
        info_set_required_semver(">=0.15.21")

    effective_inherited_vars = {"inherited_vars": inherited_vars} if inherited_vars != None else {}
    effective_optional_inherited_vars = {"optional_inherited_vars": optional_inherited_vars} if optional_inherited_vars != None else {}
    effective_run_inherited_vars = {"run_inherited_vars": run_inherited_vars} if run_inherited_vars != None else {}
    secret_inherited_vars = {"secret_inherited_vars": secret_inherited_vars} if secret_inherited_vars != None else {}

    if visibility != None:
        info_set_minimum_version("0.15.24")
    EFFECTIVE_VISIBILITY = {"visibility": visibility} if visibility != None else {}

    checkout.update_env(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        } | EFFECTIVE_VISIBILITY,
        env = {
                  "paths": paths,
                  "vars": vars,
                  "system_paths": system_paths,
              } |
              effective_inherited_vars |
              effective_optional_inherited_vars |
              effective_run_inherited_vars |
              secret_inherited_vars,
    )

def checkout_add_which_asset(
        name: str,
        which: str,
        destination: str,
        deps: list[str] = [],
        platforms: list[str] | None = None,
        type: str | None = None,
        visibility: str | dict[str, list[str]] | None = None):
    """
    Adds an asset to the destintion based on the which command.

    Using this function creates system dependencies that may not be reproducible across different systems.

    Args:
        name: The name of the rule.
        which: The name of the asset to add.
        destination: The destination path for the asset.
        deps: List of dependencies for the asset.
        type: use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        platforms: List of [platforms](/docs/builtins/#rule-options) to add the archive to.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.
    """

    if visibility != None:
        info_set_minimum_version("0.15.24")
    EFFECTIVE_VISIBILITY = {"visibility": visibility} if visibility != None else {}

    checkout.add_which_asset(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        } | EFFECTIVE_VISIBILITY,
        asset = {
            "which": which,
            "destination": destination,
        },
    )

def update_platforms_prefix(
        platforms: dict,
        add_prefix: str) -> dict:
    """
    Updates the prefix of the platforms.

    Args:
        platforms: List of [platforms](/docs/builtins/#rule-options) to add the archive to.
        add_prefix: The prefix to set.

    Returns:
        An updated list of platforms.
    """

    updated_platforms = {}
    available_platforms = info.get_supported_platforms()
    for platform in available_platforms:
        if platforms.get(platform):
            updated_platforms[platform] = platforms[platform] | {"add_prefix": add_prefix}

    return updated_platforms

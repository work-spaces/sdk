"""
Spaces working environment setup.

This is a basic environment setup. It gives the user access to system commands
so that they can work in the terminal.

"""

load("checkout.star", "checkout_update_env", "checkout_add_which_asset")
load("ws.star", "workspace_get_absolute_path")

def spaces_working_env(add_spaces_to_sysroot = False):
    """
    Sets the spaces working env which provides `/usr/bin` and `/bin` in the `PATH` so that the user can run system commands.

    Adding this checkout rule also inherits `HOME` and adds `(spaces)` to the prompt when using `source ./env`.

    Args:
        add_spaces_to_sysroot: `bool` If True, adds the spaces binary to the sysroot/bin directory.

    Returns:
        The name of the rule.
    """

    ps1 = {"PS1": "(spaces) $PS1"} if info.is_ci() == False else {}

    rule_name = "spaces_starlark_sdk_spaces_working_env"
    checkout_update_env(
        rule_name,
        system_paths = ["/usr/bin", "/bin"],
        vars = {
            "SPACES_WORKSPACE": workspace_get_absolute_path(),
        } | ps1,
        inherited_vars = ["HOME"],
    )

    if add_spaces_to_sysroot:
        checkout_add_which_asset(
            "spaces_sysroot_bin",
            which = "spaces",
            destination = "sysroot/bin/spaces",
        )

    return rule_name
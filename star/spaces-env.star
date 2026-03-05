"""
Spaces working environment setup.

This is a basic environment setup. It gives the user access to system commands
so that they can work in the terminal.

"""

load("checkout.star", "checkout_add_which_asset", "checkout_update_env")
load("ws.star", "workspace_get_absolute_path")

def spaces_working_env(add_spaces_to_sysroot: bool = False, inherit_terminal: bool = False, visibility: str | dict[str, list[str]] | None = None) -> str:
    """
    Sets the spaces working env which provides `/usr/bin` and `/bin` in the `PATH` so that the user can run system commands.

    Adding this checkout rule also inherits `HOME` and adds `(spaces)` to the prompt when using `source ./env`.

    Args:
        add_spaces_to_sysroot: If True, adds the spaces binary to the sysroot/bin directory.
        inherit_terminal: If True, inherits terminal variables. This enables `spaces shell` to work well.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.

    Returns:
        The name of the rule.
    """

    ps1 = {"PS1": "(spaces) $ "} if info.is_ci() == False else {}

    rule_name = "spaces_starlark_sdk_spaces_working_env"

    terminal_vars = [
        "COLORFGBG",
        "COLORTERM",
        "COMMAND_MODE",
        "LANG",
        "TERM",
        "TERMINFO_DIRS",
        "TMPDIR",
    ]

    checkout_update_env(
        rule_name,
        system_paths = ["/usr/bin", "/bin"],
        vars = {
            "SPACES_WORKSPACE": workspace_get_absolute_path(),
        } | ps1,
        inherited_vars = ["HOME", "USER"],
        optional_inherited_vars = terminal_vars if inherit_terminal else [],
        visibility = visibility,
    )

    if add_spaces_to_sysroot:
        checkout_add_which_asset(
            "spaces_sysroot_bin",
            which = "spaces",
            destination = "sysroot/bin/spaces",
            visibility = visibility,
        )

    return rule_name

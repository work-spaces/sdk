"""
Spaces working environment setup.

This is a basic environment setup. It gives the user access to system commands
so that they can work in the terminal.

"""

load("checkout.star", "checkout_update_env")

def spaces_working_env():
    """
    Sets the spaces working env which provides /usr/bin and /bin in the PATH so that the user can run system commands.
    """
    checkout_update_env(
        "spaces_starlark_sdk_spaces_working_env",
        system_paths = ["/usr/bin", "/bin"],
        vars = {
            "SPACES_WORKSPACE": info.get_absolute_path_to_workspace(),
            "PS1": "(spaces) $PS1",
        },
    )

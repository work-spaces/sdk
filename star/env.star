"""
Helper functions for creating environment variables.
"""

def _env_bool(value: bool):
    return "Yes" if value else "No"

def env_assign(
        name: str,
        value: str,
        help: str) -> dict:
    """
    Assigns an environment variable to the workspace.

    Args:
        name: The name of the environment variable.
        value: The value of the environment variable.
        help: Help text that will be added to the workspace.

    Returns:
        A dictionary containing the environment variable.
    """
    return {
        "name": name,
        "help": help,
        "value": {
            "Assign": {
                "value": value,
            },
        },
    }

def env_append(
        name: str,
        value: str,
        help: str,
        separator: str = ":") -> dict:
    """
    Appends a value to an environment variable.

    The value will be created if it does not exist.

    Args:
        name: The name of the environment variable.
        value: The value to append.
        separator: The separator to use.

    Returns:
        A dictionary containing the environment variable.
    """
    return {
        "name": name,
        "help": help,
        "value": {
            "Append": {
                "value": value,
                "separator": separator,
            },
        },
    }

def env_prepend(
        name: str,
        value: str,
        help: str,
        separator: str = ":") -> dict:
    """
    Prepends a value to an environment variable.

    The value will be created if it does not exist.

    Args:
        name: The name of the environment variable.
        value: The value to append.
        separator: The separator to use.

    Returns:
        A dictionary containing the environment variable.
    """
    return {
        "name": name,
        "help": help,
        "value": {
            "Prepend": {
                "value": value,
                "separator": separator,
            },
        },
    }

def env_inherit(
        name,
        help: str,
        assign_as_default = None,
        is_secret: bool = False,
        is_required: bool = False,
        is_save_at_checkout: bool = False):
    """
    Inherits an environment variable.


    Args:
        name: The name of the environment variable.
        assign_as_default: The default value to assign if the variable is not set in the calling environment.
        is_secret: If true, the value will be redacted in the logs.
        is_required: If true and no value can be inherited and not default is provided, the operation will fail.
        is_save_at_checkout: Whether the variable should be saved at checkout.

    Returns:
        A dictionary containing the environment variable.
    """
    return {
        "name": name,
        "help": help,
        "value": {
            "Inherit": {
                "assign_as_default": assign_as_default,
                "is_secret": is_secret,
                "is_required": is_required,
                "is_save_at_checkout": is_save_at_checkout,
            },
        },
    }

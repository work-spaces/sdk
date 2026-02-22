"""
Helper functions for creating environment variables.
"""

def _env_bool(value):
    return "Yes" if value else "No"

def env_assign(
        name,
        value,
        help):
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
        name,
        value,
        help,
        separator = ":"):
    """
    Appends a value to an environment variable.

    The value will be created if it does not exist.

    Args:
        name: The name of the environment variable.
        value: The value to append.
        separator: The separator to use.
        help: Help text that will be added to the workspace.

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
        name,
        value,
        help,
        separator = ":"):
    """
    Prepends a value to an environment variable.

    The value will be created if it does not exist.

    Args:
        name: The name of the environment variable.
        value: The value to append.
        separator: The separator to use.
        help: Help text that will be added to the workspace.

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
        help,
        assign_as_default = None,
        is_secret = False,
        is_required = False,
        is_save_at_checkout = False):
    """
    Inherits an environment variable.


    Args:
        name: The name of the environment variable.
        assign_as_default: The default value to assign if the variable is not set in the calling environment.
        is_secret: If true, the value will be redacted in the logs.
        is_required: If true and no value can be inherited and not default is provided, the operation will fail.
        is_save_at_checkout: Whether the variable should be saved at checkout.
        help: Help text that will be added to the workspace.

    Returns:
        A dictionary containing the environment variable.
    """
    return {
        "name": name,
        "help": help,
        "value": {
            "Inherit": {
                "assign_as_default": assign_as_default,
                "is_secret": _env_bool(is_secret),
                "is_required": _env_bool(is_required),
                "is_save_at_checkout": _env_bool(is_save_at_checkout),
            },
        },
    }

"""
Script wrappers for built-ins
"""

def script_print(message):
    """
    Print a message

    This is for debugging purposes only. It is not recommended to use this
    function for normal output.

    Args:
        message: `str` The message to print
    """
    script.print(message)

def script_get_arg(offset):
    """
    Get a command line argument

    Args:
        offset: `int` The offset of the argument to get

    Returns:
        The argument at the given offset
    """
    return script.get_arg(offset)

def script_get_args():
    """
    Get all command line arguments

    `named` arguments are of the format `--name=value`.

    Returns:
        dict: with members `[ordered]` and `{named}`
    """
    return script.get_args()

def script_set_exit_code(exit_code):
    """
    Set the exit code

    This does not exit the script. It just sets the exit code.

    Args:
        exit_code: `int` The exit code
    """
    script.set_exit_code(exit_code)

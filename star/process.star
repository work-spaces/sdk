"""
Process built-ins
"""


def process_exec(
    command,
    args = [],
    env = {},
    working_directory = None,
    stdin = None):
    """
    Executes a command when the script is evaluated.

    The command executes during evaluation. It is not recommended to run
    functions when adding rules because evalation is skipped if none of the
    starlark files have changed.

    Example:

    ```python
    process_exec(
        "ls", 
        args = ["-alt"],
        working_directory = ".",
        env = {
            "PATH": "/usr/bin:/bin"
        }
    )
    ```

    Args:
        command: The command to execute
        args: The arguments to pass to the command
        env: The environment variables to set
        working_directory: The working directory to execute the command in
        stdin: The standard input to pass to the command

    Returns:
        dict: with members `status`, `stdout`, and `stderr`
    """
    return process.exec({
        "command": command, 
        "args": args, 
        "env": env, 
        "working_directory": working_directory, 
        "stdin": stdin})
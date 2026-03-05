"""
Shell functions
"""

load("run.star", "RUN_EXPECT_SUCCESS", "run_add_exec")

def cp(
        name: str,
        source: str,
        destination: str,
        options: list[str] = [],
        deps: list[str] = [],
        type: str | None = None,
        inputs: list[str] | None = None,
        help: str | None = None,
        working_directory: str | None = None,
        visibility: str | dict[str, list[str]] | None = None,
        expect: str = RUN_EXPECT_SUCCESS):
    """
    Copy a file or directory from source to destination.

    Args:
        name: The name of the rule.
        source: The source file or directory.
        destination: The destination file or directory.
        options: The options for the copy command.
        deps: The dependencies for the copy command.
        type: The type of the command.
        inputs: The inputs for the command.
        help: The help message for the command.
        working_directory: The working directory for the command.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.
        expect: Success | Failure
    """

    run_add_exec(
        name,
        "cp",
        args = options + [source, destination],
        deps = deps,
        type = type,
        inputs = inputs,
        expect = expect,
        help = help,
        working_directory = working_directory,
        visibility = visibility,
    )

def mv(
        name: str,
        source: str,
        destination: str,
        options: list[str] = [],
        deps: list[str] = [],
        type: str | None = None,
        inputs: list[str] | None = None,
        help: str | None = None,
        working_directory: str | None = None,
        visibility: str | dict[str, list[str]] | None = None,
        expect: str = RUN_EXPECT_SUCCESS):
    """
    Rename a file or directory from source to destination.

    Args:
        name: The name of the rule.
        source: The source file or directory.
        destination: The destination file or directory.
        options: The options for the move command.
        deps: The dependencies for the move command.
        type: The type of the command.
        inputs: The inputs for the command.
        help: The help message for the command.
        working_directory: The working directory for the command.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.
        expect: Success|Failure
    """

    run_add_exec(
        name,
        "mv",
        args = options + [source, destination],
        deps = deps,
        type = type,
        inputs = inputs,
        expect = expect,
        help = help,
        working_directory = working_directory,
        visibility = visibility,
    )

def ln(
        name: str,
        source: str,
        destination: str,
        options: list[str] = [],
        deps: list[str] = [],
        type: str | None = None,
        inputs: list[str] | None = None,
        help: str | None = None,
        working_directory: str | None = None,
        visibility: str | dict[str, list[str]] | None = None,
        expect: str = RUN_EXPECT_SUCCESS):
    """
    Create a link from source to destination.

    Args:
        name: The name of the rule.
        source: The source file or directory.
        destination: destination or target (to be created).
        options: The options for the copy command.
        deps: The dependencies for the copy command.
        type: The type of the command.
        inputs: The inputs for the command.
        help: The help message for the command.
        working_directory: The working directory for the command.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.
        expect: Success|Failure
    """

    run_add_exec(
        name,
        "ln",
        args = options + [source, destination],
        deps = deps,
        type = type,
        inputs = inputs,
        expect = expect,
        help = help,
        working_directory = working_directory,
        visibility = visibility,
    )

def ls(
        name: str,
        path: str,
        options: list[str] = [],
        deps: list[str] = [],
        type: str | None = None,
        inputs: list[str] | None = None,
        help: str | None = None,
        working_directory: str | None = None,
        visibility: str | dict[str, list[str]] | None = None,
        expect: str = RUN_EXPECT_SUCCESS):
    """
    Run ls (this can be handy for checking if something exists).

    Args:
        name: The name of the rule.
        path: The directory to list.
        options: The options for the ls command.
        deps: The dependencies for the ls command.
        type: The type of the command.
        inputs: The inputs for the command.
        help: The help message for the command.
        working_directory: The working directory for the command.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.
        expect: Success|Failure
    """

    run_add_exec(
        name,
        "ls",
        args = options + [path],
        deps = deps,
        type = type,
        inputs = inputs,
        expect = expect,
        help = help,
        working_directory = working_directory,
        visibility = visibility,
    )

def mkdir(
        name: str,
        path: str,
        options: list[str] = [],
        deps: list[str] = [],
        type: str | None = None,
        inputs: list[str] | None = None,
        help: str | None = None,
        working_directory: str | None = None,
        visibility: str | dict[str, list[str]] | None = None,
        expect: str = RUN_EXPECT_SUCCESS):
    """
    Create a new directory.

    Args:
        name: The name of the rule.
        path: The source file or directory.
        options: The options for the copy command.
        deps: The dependencies for the copy command.
        type: The type of the command.
        inputs: The inputs for the command.
        help: The help message for the command.
        working_directory: The working directory for the command.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.
        expect: Success|Failure
    """

    run_add_exec(
        name,
        "mkdir",
        args = options + [path],
        deps = deps,
        type = type,
        inputs = inputs,
        expect = expect,
        help = help,
        working_directory = working_directory,
        visibility = visibility,
    )

def chmod(
        name: str,
        mode: str,
        path: str,
        deps: list[str] = [],
        type: str | None = None,
        inputs: list[str] | None = None,
        help: str | None = None,
        working_directory: str | None = None,
        visibility: str | dict[str, list[str]] | None = None,
        expect: str = RUN_EXPECT_SUCCESS):
    """
    Changes the mode of a file or directory.

    Args:
        name: The name of the rule.
        mode: The source file or directory.
        path: The path/file to change permissions for.
        deps: The dependencies for the copy command.
        type: The type of the command.
        inputs: The inputs for the command.
        help: The help message for the command.
        working_directory: The working directory for the command.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.
        expect: Success|Failure
    """

    run_add_exec(
        name,
        "chmod",
        args = [mode, path],
        deps = deps,
        type = type,
        inputs = inputs,
        expect = expect,
        help = help,
        working_directory = working_directory,
        visibility = visibility,
    )

def shell(
        name: str,
        script: str,
        shell: str = "bash",
        options: list[str] = ["-c"],
        expect: str = RUN_EXPECT_SUCCESS,
        type: str | None = None,
        inputs: list[str] | None = None,
        help: str | None = None,
        working_directory: str | None = None,
        visibility: str | dict[str, list[str]] | None = None,
        deps: list[str] = []):
    """
    Add a run rule that executes a shell script.

    Examples:

    ```python
    shell(
        name = "echo",
        script = "echo hello",
    )
    ```

    ```python
    shell(
        name = "echo",
        script = "ls some_file && rm some_file",
    )
    ```

    Args:
        name: name of the rule
        script: text of the script to run
        shell: shell to use (default is `bash`)
        options: options to pass before script default is `-c`
        expect: Success | Failure
        type: Optional | All (default is Optional)
        inputs: The inputs for the command.
        help: The help message for the command.
        working_directory: working directory (default is workspace root)
        visibility: Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.
        deps: rule dependencies
    """

    run_add_exec(
        name,
        command = shell,
        args = options + [script],
        type = type,
        deps = deps,
        inputs = inputs,
        help = help,
        working_directory = working_directory,
        visibility = visibility,
        expect = expect,
    )

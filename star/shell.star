"""
Shell functions
"""

load("run.star", "RUN_EXPECT_SUCCESS", "run_add_exec")

def cp(
        name,
        source,
        destination,
        options = [],
        deps = [],
        type = None,
        inputs = None,
        working_directory = None,
        expect = RUN_EXPECT_SUCCESS):
    """
    Copy a file or directory from source to destination.

    Args:
        name: `str` The name of the rule.
        source: `str` The source file or directory.
        destination: `str` The destination file or directory.
        options: `[str]` The options for the copy command.
        deps: `[str]` The dependencies for the copy command.
        type: `enum` The type of the command.
        inputs: `[str]` The inputs for the command.
        working_directory: `str` The working directory for the command.
        expect: `enum` Success | Failure
    """

    run_add_exec(
        name,
        "cp",
        args = options + [source, destination],
        deps = deps,
        type = type,
        inputs = inputs,
        expect = expect,
        working_directory = working_directory,
    )

def mv(
        name,
        source,
        destination,
        options = [],
        deps = [],
        type = None,
        inputs = None,
        working_directory = None,
        expect = RUN_EXPECT_SUCCESS):
    """
    Rename a file or directory from source to destination.

    Args:
        name: The name of the rule.
        source: `str` The source file or directory.
        destination: `str` The destination file or directory.
        options: `[str]` The options for the move command.
        deps: `[str]` The dependencies for the move command.
        type: `enum` The type of the command.
        inputs: `[str]` The inputs for the command.
        working_directory: `str` The working directory for the command.
        expect: `enum` Success | Failure
    """

    run_add_exec(
        name,
        "mv",
        args = options + [source, destination],
        deps = deps,
        type = type,
        inputs = inputs,
        expect = expect,
        working_directory = working_directory,
    )

def ln(
        name,
        source,
        destination,
        options = [],
        deps = [],
        type = None,
        inputs = None,
        working_directory = None,
        expect = RUN_EXPECT_SUCCESS):
    """
    Create a link from source to destination.

    Args:
        name: `str` The name of the rule.
        source: `str` The source file or directory.
        destination: `str` destination or target (to be created).
        options: `[str]` The options for the copy command.
        deps: `[str]` The dependencies for the copy command.
        type: `enum` The type of the command.
        inputs: `[str]` The inputs for the command.
        working_directory: `str` The working directory for the command.
        expect: `enum` Success | Failure
    """

    run_add_exec(
        name,
        "ln",
        args = options + [source, destination],
        deps = deps,
        type = type,
        inputs = inputs,
        expect = expect,
        working_directory = working_directory,
    )

def ls(
        name,
        path,
        options = [],
        deps = [],
        type = None,
        inputs = None,
        working_directory = None,
        expect = RUN_EXPECT_SUCCESS):
    """
    Run ls (this can be handy for checking if something exists).

    Args:
        name: `str` The name of the rule.
        path: `str` The directory to list.
        options: `[str]` The options for the ls command.
        deps: `[str]` The dependencies for the ls command.
        type: `enum` The type of the command.
        inputs: `[str]` The inputs for the command.
        working_directory: `str` The working directory for the command.
        expect: `enum` Success | Failure
    """

    run_add_exec(
        name,
        "ls",
        args = options + [path],
        deps = deps,
        type = type,
        inputs = inputs,
        expect = expect,
        working_directory = working_directory,
    )

def mkdir(
        name,
        path,
        options = [],
        deps = [],
        type = None,
        inputs = None,
        working_directory = None,
        expect = RUN_EXPECT_SUCCESS):
    """
    Create a new directory.

    Args:
        name: The name of the rule.
        path: The source file or directory.
        options: The options for the copy command.
        deps: The dependencies for the copy command.
        type: The type of the command.
        inputs: The inputs for the command.
        working_directory: The working directory for the command.
        expect: `enum` Success | Failure
    """

    run_add_exec(
        name,
        "mkdir",
        args = options + [path],
        deps = deps,
        type = type,
        inputs = inputs,
        expect = expect,
        working_directory = working_directory,
    )

def chmod(
        name,
        mode,
        path,
        deps = [],
        type = None,
        inputs = None,
        working_directory = None,
        expect = RUN_EXPECT_SUCCESS):
    """
    Changes the mode of a file or directory.

    Args:
        name: `str` The name of the rule.
        mode: The source file or directory.
        path: `str` The path/file to change permissions for.
        deps: `[str]` The dependencies for the copy command.
        type: `enum` The type of the command.
        inputs: `[str]` The inputs for the command.
        working_directory: `str` The working directory for the command.
        expect: `enum` Success | Failure
    """

    run_add_exec(
        name,
        "chmod",
        args = [mode, path],
        deps = deps,
        type = type,
        inputs = inputs,
        expect = expect,
        working_directory = working_directory,
    )

def shell(
        name,
        script,
        shell = "bash",
        options = ["-c"],
        expect = RUN_EXPECT_SUCCESS,
        type = None,
        inputs = None,
        working_directory = None,
        deps = []):
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
        name: `str` name of the rule
        script: `str` text of the script to run
        shell: `str` shell to use (default is `bash`)
        options: `[str]` options to pass before script default is `-c`
        expect: `enum` Success | Failure
        type: `enum` Optional | All (default is Optional)
        inputs: `[str]` The inputs for the command.
        working_directory: `str` working directory (default is workspace root)
        deps: `[str]` rule dependencies
    """

    run_add_exec(
        name,
        command = shell,
        args = options + [script],
        type = type,
        deps = deps,
        inputs = inputs,
        working_directory = working_directory,
        expect = expect,
    )

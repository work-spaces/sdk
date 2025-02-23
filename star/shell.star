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
        name (str): The name of the function.
        source (str): The source file or directory.
        destination (str): The destination file or directory.
        options (list): The options for the copy command.
        deps (list): The dependencies for the copy command.
        type (str): The type of the command.
        inputs (list): The inputs for the command.
        working_directory (str): The working directory for the command.
        expect (str): Success | Failure
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
        working_directory = None,
        expect = RUN_EXPECT_SUCCESS):
    """
    Rename a file or directory from source to destination.

    Args:
        name (str): The name of the function.
        source (str): The source file or directory.
        destination (str): The destination file or directory.
        options (list): The options for the copy command.
        deps (list): The dependencies for the copy command.
        type (str): The type of the command.
        working_directory (str): The working directory for the command.
        expect (str): Success | Failure
    """

    run_add_exec(
        name,
        "mv",
        args = options + [source, destination],
        deps = deps,
        type = type,
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
        working_directory = None,
        expect = RUN_EXPECT_SUCCESS):
    """
    Create a link from source to destination.

    Args:
        name (str): The name of the function.
        source (str): The source file or directory.
        destination (str): destination or target (to be created).
        options (list): The options for the copy command.
        deps (list): The dependencies for the copy command.
        type (str): The type of the command.
        working_directory (str): The working directory for the command.
        expect (str): Success | Failure
    """

    run_add_exec(
        name,
        "ln",
        args = options + [source, destination],
        deps = deps,
        type = type,
        expect = expect,
        working_directory = working_directory,
    )

def ls(
        name,
        path,
        options = [],
        deps = [],
        type = None,
        working_directory = None,
        expect = RUN_EXPECT_SUCCESS):
    """
    Run ls (this can be handy for checking if something exists).

    Args:
        name (str): The name of the function.
        path (str): The source file or directory.
        options (list): The options for the copy command.
        deps (list): The dependencies for the copy command.
        type (str): The type of the command.
        working_directory (str): The working directory for the command.
        expect (str): Success | Failure
    """

    run_add_exec(
        name,
        "ls",
        args = options + [path],
        deps = deps,
        type = type,
        expect = expect,
        working_directory = working_directory,
    )

def mkdir(
        name,
        path,
        options = [],
        deps = [],
        type = None,
        working_directory = None,
        expect = RUN_EXPECT_SUCCESS):
    """
    Create a new directory.

    Args:
        name (str): The name of the function.
        path (str): The source file or directory.
        options (list): The options for the copy command.
        deps (list): The dependencies for the copy command.
        type (str): The type of the command.
        working_directory (str): The working directory for the command.
        expect (str): Success | Failure
    """

    run_add_exec(
        name,
        "mkdir",
        args = options + [path],
        deps = deps,
        type = type,
        expect = expect,
        working_directory = working_directory,
    )

def chmod(
        name,
        mode,
        path,
        deps = [],
        type = None,
        working_directory = None,
        expect = RUN_EXPECT_SUCCESS):
    """
    Changes the mode of a file or directory.

    Args:
        name (str): The name of the function.
        mode (str): The source file or directory.
        path (list): The options for the copy command.
        deps (list): The dependencies for the copy command.
        type (str): The type of the command.
        working_directory (str): The working directory for the command.
        expect (str): Success | Failure
    """

    run_add_exec(
        name,
        "chmod",
        args = [mode, path],
        deps = deps,
        type = type,
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
    working_directory = None,
    deps = []):
    """
    Execute a string as a shell script

    Args:
        name (str): name of the rule
        script (str): text of the script to run
        shell (str): shell to use (default is bash)
        options (str): options to pass before script default is '-c'
        expect (str): Success or Failure
        type: Optional or All (default is Optional)
        working_directory: workspace working directory (default is workspace root)
        deps: rule dependencies
    """

    run_add_exec(
        name,
        command = shell,
        args = options + [script],
        type = type,
        deps = deps,
        working_directory = working_directory,
        expect = expect
    )

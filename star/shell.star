"""
Shell functions
"""

load("run.star", "run_add_exec")

def cp(
        name,
        source,
        destination,
        options = [],
        deps = [],
        type = None):
    """
    Copy a file or directory from source to destination.

    Args:
        name (str): The name of the function.
        source (str): The source file or directory.
        destination (str): The destination file or directory.
        options (list): The options for the copy command.
        deps (list): The dependencies for the copy command.
        type (str): The type of the command.
    """

    run_add_exec(
        name,
        "cp",
        args = options + [source, destination],
        deps = deps,
        type = type,
    )

def mv(
        name,
        source,
        destination,
        options = [],
        deps = [],
        type = None):
    """
    Rename a file or directory from source to destination.

    Args:
        name (str): The name of the function.
        source (str): The source file or directory.
        destination (str): The destination file or directory.
        options (list): The options for the copy command.
        deps (list): The dependencies for the copy command.
        type (str): The type of the command.
    """

    run_add_exec(
        name,
        "mv",
        args = options + [source, destination],
        deps = deps,
        type = type,
    )

def ln(
        name,
        source,
        destination,
        options = [],
        deps = [],
        type = None):
    """
    Create a link from source to destination.

    Args:
        name (str): The name of the function.
        source (str): The source file or directory.
        destination (str): destination or target (to be created).
        options (list): The options for the copy command.
        deps (list): The dependencies for the copy command.
        type (str): The type of the command.
    """

    run_add_exec(
        name,
        "ln",
        args = options + [source, destination],
        deps = deps,
        type = type,
    )

def ls(
        name,
        path,
        options = [],
        deps = [],
        type = None):
    """
    Run ls (this can be handy for checking if something exists).

    Args:
        name (str): The name of the function.
        path (str): The source file or directory.
        options (list): The options for the copy command.
        deps (list): The dependencies for the copy command.
        type (str): The type of the command.
    """

    run_add_exec(
        name,
        "ls",
        args = options + [path],
        deps = deps,
        type = type,
    )

def mkdir(
        name,
        path,
        options = [],
        deps = [],
        type = None):
    """
    Create a new directory.

    Args:
        name (str): The name of the function.
        path (str): The source file or directory.
        options (list): The options for the copy command.
        deps (list): The dependencies for the copy command.
        type (str): The type of the command.
    """

    run_add_exec(
        name,
        "mkdir",
        args = options + [path],
        deps = deps,
        type = type,
    )

def chmod(
        name,
        permissions,
        source,
        deps = [],
        type = None):
    """
    Changes the permissions of a file or directory.

    Args:
        name (str): The name of the function.
        permissions (str): The source file or directory.
        source (list): The options for the copy command.
        deps (list): The dependencies for the copy command.
        type (str): The type of the command.
    """

    run_add_exec(
        name,
        "chmod",
        args = [permissions, source],
        deps = deps,
        type = type,
    )

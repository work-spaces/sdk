"""
User friendly wrapper functions for the spaces run built-in functions.
"""

def run_add_exec(
        rule_name,
        command,
        help = None,
        args = [],
        env = {},
        deps = [],
        inputs = None,
        type = None,
        working_directory = None,
        platforms = None):
    """
    Adds a command to the run dependency graph

    Args:
        rule_name (str): The name of the rule.
        command (str): The name of the rule.
        help (str): The help message for the rule.
        args (str): The git repository URL to clone
        type (str): The exec type ("Run"| "Setup" | "Optional")
        deps (str): The branch or commit hash to checkout
        inputs (list): List of globs to specify the inputs
        env (dict): key value pairs of environment variables
        working_directory (str): The branch or commit hash to checkout
        platforms (list): The branch or commit hash to checkout
    """
    run.add_exec(
        rule = {
            "name": rule_name,
            "deps": deps,
            "platforms": platforms,
            "help": help,
            "type": type,
            "inputs": inputs,
        },
        exec = {
            "command": command,
            "args": args,
            "working_directory": working_directory,
            "env": env,
        },
    )

def run_add_target(
        name,
        deps,
        platforms = None):
    """
    Adds a target to the workspace.

    Args:
        name (str): The name of the rule.
        deps (list): List of dependencies for the target.
        platforms (list): List of platforms to build the target for (default is all).
    """
    run.add_target(
        rule = {"name": name, "deps": deps, "platforms": platforms},
    )

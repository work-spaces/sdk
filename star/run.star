"""
User friendly wrapper functions for the spaces run built-in functions.
"""

RUN_INPUTS_ONCE = []
RUN_INPUTS_ALWAYS = None
RUN_TYPE_ALL = "Run"

def run_add_exec_setup(
        name,
        command,
        help = None,
        args = [],
        env = {},
        deps = [],
        working_directory = None,
        platforms = None,
        log_level = None,
        expect = "Success"):
    """
    Adds a command as a setup rule. It will run only once and all run rules will depend on it.

    Args:
        name (str): The name of the rule.
        command (str): The name of the rule.
        help (str): The help message for the rule.
        args (str): The git repository URL to clone
        type (str): The exec type ("Run"| "Setup" | "Optional")
        deps (str): The branch or commit hash to checkout
        env (dict): key value pairs of environment variables
        working_directory (str): The branch or commit hash to checkout
        platforms (list): Platforms to run on (default is all).
        log_level (str): The log level to use None|App
        expect (str): The expected result of the command Success|Failure|Any. (default is Success)
    """

    run.add_exec(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "help": help,
            "type": "Setup",
            "inputs": RUN_INPUTS_ONCE,
        },
        exec = {
            "command": command,
            "args": args,
            "working_directory": working_directory,
            "env": env,
            "expect": expect,
            "log_level": log_level,
        },
    )

def run_add_exec(
        name,
        command,
        help = None,
        args = [],
        env = {},
        deps = [],
        inputs = RUN_INPUTS_ALWAYS,
        type = None,
        working_directory = None,
        platforms = None,
        log_level = None,
        expect = "Success"):
    """
    Adds a command to the run dependency graph

    Args:
        name (str): The name of the rule.
        command (str): The name of the rule.
        help (str): The help message for the rule.
        args (str): The git repository URL to clone
        type (str): The exec type ("Run"| "Setup" | "Optional")
        deps (str): The branch or commit hash to checkout
        inputs (list): List of globs to specify the inputs
        env (dict): key value pairs of environment variables
        working_directory (str): The branch or commit hash to checkout
        platforms (list): Platforms to run on (default is all).
        log_level (str): The log level to use None|App
        expect (str): The expected result of the command Success|Failure|Any. (default is Success)
    """

    effective_type = type if type != None else "Optional"

    run.add_exec(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "help": help,
            "type": effective_type,
            "inputs": inputs,
        },
        exec = {
            "command": command,
            "args": args,
            "working_directory": working_directory,
            "env": env,
            "expect": expect,
            "log_level": log_level,
        },
    )

def run_add_kill_exec(
        name,
        target,
        signal = "Kill",
        help = None,
        expect = "Success",
        deps = [],
        type = None,
        platforms = None):
    """
    Adds a command to the run dependency graph

    Args:
        name (str): The name of the rule.
        target (str): The name of the rule to kill.
        signal (str): The signal to send to the target.
        help (str): The help message for the rule.
        expect (str): The expected result of the kill. (default is Success)
        deps (str): Run rule dependencies.
        type (str): The exec type ("Run"| "Setup" | "Optional")
        platforms (list): Platforms to run on (default is all).
    """
    run.add_kill_exec(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "help": help,
            "type": type,
            "inputs": None,
        },
        kill = {
            "target": target,
            "signal": signal,
            "expect": expect,
        },
    )

def run_add_target(
        name,
        deps,
        help = None,
        type = None,
        platforms = None):
    """
    Adds a target to the workspace.

    This rule can be used to consilidate dependencies into a single target.

    Args:
        name (str): The name of the rule.
        deps (list): List of dependencies for the target.
        platforms (list): List of platforms to build the target for (default is all).
        type (str): The exec type ("Run"| "Setup" | "Optional")
        help (str): The help message for the rule.
    """
    run.add_target(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
            "help": help,
        },
    )

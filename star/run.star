"""
User friendly wrapper functions for the spaces run built-in functions.
"""

RUN_INPUTS_ONCE = []
RUN_INPUTS_ALWAYS = None
RUN_TYPE_ALL = "Run"

# Print the output of the run rule while running spaces
RUN_LOG_LEVEL_APP = "App"

RUN_EXPECT_SUCCESS = "Success"
RUN_EXPECT_FAILURE = "Failure"
RUN_EXPECT_ANY = "Any"

# Kill Signals
RUN_SIGNAL_HUP = "HUP"
RUN_SIGNAL_INT = "INT"
RUN_SIGNAL_QUIT = "QUIT"
RUN_SIGNAL_ABORT = "ABRT"
RUN_SIGNAL_KILL = "KILL"
RUN_SIGNAL_ALARM = "ALRM"
RUN_SIGNAL_TERMINATE = "TERM"
RUN_SIGNAL_USER1 = "USR1"
RUN_SIGNAL_USER2 = "USR2"

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
        redirect_stdout = None,
        timeout = None,
        expect = RUN_EXPECT_SUCCESS):
    """
    Adds a command as a setup rule. It will run only once and all run rules will depend on it.

    Args:
        name (str): The name of the rule.
        command (str): The name of the rule.
        help (str): The help message for the rule.
        args (str): The git repository URL to clone
        deps (str): The branch or commit hash to checkout
        env (dict): key value pairs of environment variables
        working_directory (str): The branch or commit hash to checkout
        platforms (list): Platforms to run on (default is all).
        log_level (str): The log level to use None|App
        redirect_stdout: The file to redirect stdout to.
        timeout: Number of seconds to run before sending a kill signal.
        expect (str): The expected result of the command Success|Failure|Any. (default is Success)
    """

    EFFECTIVE_TIMEOUT = {"timeout": timeout} if timeout != None else {}

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
            "redirect_stdout": redirect_stdout,
        } | EFFECTIVE_TIMEOUT,
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
        redirect_stdout = None,
        timeout = None,
        expect = RUN_EXPECT_SUCCESS):
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
        redirect_stdout: The file to redirect stdout to.
        timeout: Number of seconds to run before sending a kill signal.
    """

    EFFECTIVE_TYPE = type if type != None else "Optional"
    EFFECTIVE_TIMEOUT = {"timeout": timeout} if timeout != None else {}

    run.add_exec(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "help": help,
            "type": EFFECTIVE_TYPE,
            "inputs": inputs,
        },
        exec = {
            "command": command,
            "args": args,
            "working_directory": working_directory,
            "env": env,
            "expect": expect,
            "log_level": log_level,
            "redirect_stdout": redirect_stdout,
        } | EFFECTIVE_TIMEOUT,
    )

def run_add_kill_exec(
        name,
        target,
        signal = RUN_SIGNAL_KILL,
        help = None,
        expect = RUN_EXPECT_SUCCESS,
        deps = [],
        type = None,
        platforms = None):
    """
    Adds a target that will send a signal to another target.

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

    EFFECTIVE_TYPE = type if type != None else "Optional"

    run.add_kill_exec(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "help": help,
            "type": EFFECTIVE_TYPE,
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

def run_add_to_all(
        name,
        deps):
    """
    Adds the dependencies to name and to the phantom all target.

    Targets will run with `spaces run`.

    Args:
        name (str): The name of the rule.
        deps (list): List of dependencies to run with `spaces run`
    """

    run_add_target(name, deps, type = RUN_TYPE_ALL)

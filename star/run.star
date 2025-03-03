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
RUN_SIGNAL_HUP = "Hup"
RUN_SIGNAL_INT = "Int"
RUN_SIGNAL_QUIT = "Quit"
RUN_SIGNAL_ABORT = "Abort"
RUN_SIGNAL_KILL = "Kill"
RUN_SIGNAL_ALARM = "Alarm"
RUN_SIGNAL_TERMINATE = "Terminate"
RUN_SIGNAL_USER1 = "User1"
RUN_SIGNAL_USER2 = "User2"

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
        name: The name of the rule.
        command: The command to execute.
        help: The help message for the rule.
        args: The arguments to pass to the command
        deps: The rule dependencies
        env: key value pairs of environment variables
        working_directory: The directory to run the command (default is workspace root).
        platforms: Platforms to run on (default is all).
        log_level: The log level to use None|App
        redirect_stdout: The file to redirect stdout to (prefer to parse the log file).
        timeout: Number of seconds to run before sending a kill signal.
        expect: The expected result of the command Success|Failure|Any. (default is Success)
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
        name: The name of the rule.
        command: The command to execute.
        help: The help message for the rule.
        args: The arguments to pass to the command.
        type: The exec type ("Run"| "Setup" | "Optional")
        deps: The rule dependencies that must be run before this command
        inputs: List of globs to specify the inputs. If the inputs are unchanged, the command will not run.
        env: key value pairs of environment variables
        working_directory: The directory to run the command (default is workspace root).
        platforms: Platforms to run on (default is all).
        log_level: The log level to use None|App
        expect: The expected result of the command Success|Failure|Any. (default is Success)
        redirect_stdout: The file to redirect stdout to (prefer to parse the log file).
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
        name: The name of the rule.
        target: The name of the rule to kill.
        signal: The signal to send to the target.
        help: The help message for the rule.
        expect: The expected result of the kill. (default is Success)
        deps: Run rule dependencies.
        type: The exec type ("Run"| "Setup" | "Optional")
        platforms: Platforms to run on (default is all).
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

    This rule can be used to consolidate dependencies into a single target.

    Args:
        name: The name of the rule.
        deps: List of dependencies for the target.
        platforms: List of platforms to build the target for (default is all).
        type: The exec type ("Run"| "Setup" | "Optional")
        help: The help message for the rule.
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
    Creates a target rule called name with deps and part of `:all`.

    Targets will run with `spaces run`.

    Args:
        name: The name of the rule.
        deps: List of dependencies to run with `spaces run`
    """

    run_add_target(name, deps, type = RUN_TYPE_ALL)

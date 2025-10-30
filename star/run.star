"""
User friendly wrapper functions for the spaces run built-in functions.
"""

load("info.star", "info_get_platform_name")

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

# Provide thin wrapper for constants so that they can have docstrings
def run_inputs_once():
    """
    Assign `inputs` to `[]` to run the command once.

    Returns:
        list: []
    """
    return RUN_INPUTS_ONCE

def run_inputs_always():
    """
    Assign `inputs` to `None` to run the command every time.

    Returns:
        None
    """
    return RUN_INPUTS_ALWAYS

def run_type_all():
    """
    Assign `type` to `Run` to run the command with `spaces run`.

    The rules marked as `Run` are part of the `//:all` target.

    ```sh
    spaces run //:all
    ```

    Returns:
        str: "Run"
    """
    return RUN_TYPE_ALL

def run_log_level_app():
    """
    Print the output of the run rule while running spaces

    Returns:
        str: "App"
    """
    return RUN_LOG_LEVEL_APP

def run_expect_success():
    """
    Expect the command to succeed

    Returns:
        str: "Success"
    """
    return RUN_EXPECT_SUCCESS

def run_expect_failure():
    """
    Expect the command to fail.

    If the command fails and is expected to fail, spaces exits successfully.

    Returns:
        str: "Failure"
    """
    return RUN_EXPECT_FAILURE

def run_expect_any():
    """
    Expect the command to succeed or fail.

    `spaces` exits successfully if the command succeeds or fails.

    Returns:
        str: "Any"
    """
    return RUN_EXPECT_ANY

def run_signal_hup():
    """
    Gets the Hangup signal
    """
    return RUN_SIGNAL_HUP

def run_signal_int():
    """
    Gets the Interrupt signal
    """
    return RUN_SIGNAL_INT

def run_signal_quit():
    """
    Gets the Quit signal
    """
    return RUN_SIGNAL_QUIT

def run_signal_abort():
    """
    Gets the Abort signal
    """
    return RUN_SIGNAL_ABORT

def run_signal_kill():
    """
    Gets the Kill signal
    """
    return RUN_SIGNAL_KILL

def run_signal_alarm():
    """
    Gets the Alarm signal
    """
    return RUN_SIGNAL_ALARM

def run_signal_terminate():
    """
    Gets the Terminate signal
    """
    return RUN_SIGNAL_TERMINATE

def run_signal_user1():
    """
    Gets the User1 signal
    """
    return RUN_SIGNAL_USER1

def run_signal_user2():
    """
    Gets the User2 signal
    """
    return RUN_SIGNAL_USER2

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

    All setup rules can be executed with:

    ```sh
    spaces run //:setup
    ```

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

def run_add_exec_test(
        name,
        command,
        help = None,
        args = [],
        env = {},
        deps = [],
        inputs = RUN_INPUTS_ALWAYS,
        working_directory = None,
        platforms = None,
        log_level = None,
        redirect_stdout = None,
        timeout = None,
        expect = RUN_EXPECT_SUCCESS):
    """
    Adds a command as a test rule.

    All test rules can be executed with:

    ```sh
    spaces run //:test
    ```

    Args:
        name: The name of the rule.
        command: The command to execute.
        help: The help message for the rule.
        args: The arguments to pass to the command
        deps: The rule dependencies
        inputs: List of globs to specify the inputs. If the inputs are unchanged, the command will not run.
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
            "type": "Test",
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

def run_add_exec_clean(
        name,
        command,
        help = None,
        args = [],
        env = {},
        deps = [],
        inputs = RUN_INPUTS_ALWAYS,
        working_directory = None,
        platforms = None,
        log_level = None,
        redirect_stdout = None,
        timeout = None,
        expect = RUN_EXPECT_SUCCESS):
    """
    Adds a command as a clean rule.

    All test rules can be executed with:

    ```sh
    spaces run //:clean
    ```

    Args:
        name: The name of the rule.
        command: The command to execute.
        help: The help message for the rule.
        args: The arguments to pass to the command
        deps: The rule dependencies
        inputs: List of globs to specify the inputs. If the inputs are unchanged, the command will not run.
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
            "type": "Clean",
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

def run_add_archive(
        name,
        archive_name,
        deps,
        version,
        source_directory,
        suffix = "tar.gz",
        includes = None,
        excludes = None,
        platform = None):
    """
    Adds an archive target to the workspace.

    This rule can be used to consolidate dependencies into a single target.

    Args:
        name: The name of the rule.
        deps: List of dependencies to run with `spaces run`
        version: The version of the archive.
        source_directory: The directory containing the source files to archive.
        includes: List of globs to include in the archive.
        excludes: List of globs to exclude from the archive.
        platform: The platform to build the target for (default is all).

    Returns:
        A tuple containing (<path to the archive>, <sha256 checksum of the archive>).
    """

    effective_platform = info_get_platform_name() if platform == None else platform

    archive_info = {
        "input": source_directory,
        "name": archive_name,
        "version": version,
        "driver": suffix,
        "platform": effective_platform,
        "includes": includes,
        "excludes": excludes,
    }

    run.add_archive(
        rule = {"name": name, "deps": deps},
        archive = archive_info,
    )

    archive_output_info = workspace_get_build_archive_info(name, archive = archive_info)

    return (archive_output_info["archive_path"], archive_output_info["sha256_path"])

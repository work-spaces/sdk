"""
User friendly wrapper functions for the spaces run built-in functions.
"""

load("info.star", "info_get_platform_name")
load("ws.star", "workspace_get_build_archive_info")

RUN_INPUTS_ONCE = []
RUN_INPUTS_ALWAYS = None
RUN_TYPE_ALL = "Run"
RUN_TYPE_DEFAULT = "Optional"
RUN_TYPE_TEST = "Test"
RUN_TYPE_SETUP = "Setup"
RUN_TYPE_PRECOMMIT = "PreCommit"
RUN_TYPE_CLEAN = "Clean"
RUN_TYPES = [
    RUN_TYPE_ALL,
    RUN_TYPE_TEST,
    RUN_TYPE_SETUP,
    RUN_TYPE_PRECOMMIT,
    RUN_TYPE_CLEAN,
]

# Print the output of the run rule while running spaces
RUN_LOG_LEVEL_APP = "App"
RUN_LOG_LEVEL_PASSTHROUGH = "Passthrough"

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

def run_type_test():
    """
    The rules added as `Test` are part of the `//:test` target.

    ```sh
    spaces run //:test
    ```

    Returns:
        str: "Test"
    """
    return RUN_TYPE_TEST

def run_type_setup():
    """
    The rules added as `Setup` are part of the `//:setup` target.

    ```sh
    spaces run //:setup
    ```

    Returns:
        str: "Setup"
    """
    return RUN_TYPE_SETUP

def run_type_precommit():
    """
    The rules added as `PreCommit` are part of the `//:pre-commit` target.

    ```sh
    spaces run //:pre-commit
    ```

    Returns:
        str: "PreCommit"
    """
    return RUN_TYPE_PRECOMMIT

def run_log_level_app():
    """
    Print the output of the run rule while running spaces

    Returns:
        str: "App"
    """
    return RUN_LOG_LEVEL_APP

def run_log_level_passthrough():
    """
    Print the output of the run rule while running spaces with no additional markings

    Returns:
        str: "Passthrough"
    """
    return RUN_LOG_LEVEL_PASSTHROUGH

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
            "type": RUN_TYPE_SETUP,
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

def run_add_exec_precommit(
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
    Adds a command as a pre-commit rule.

    All pre-commit rules can be executed with:

    ```sh
    spaces run //:pre-commit
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
            "type": RUN_TYPE_PRECOMMIT,
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
            "type": RUN_TYPE_CLEAN,
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
        name: `str` The name of the rule.
        command: `str` The command to execute.
        help: `str` The help message for the rule.
        args: `[str]` The arguments to pass to the command.
        type: `str` The exec type (Run|Setup|Optional (default)|PreCommit|Clean|Test)
        deps: `[str]`The rule dependencies that must be run before this command
        inputs: `[str]`List of globs to specify the inputs. If the inputs are unchanged, the command will not run.
        env: `dict` key value pairs of environment variables
        working_directory: `str` The directory to run the command (default is workspace root).
        platforms: `[str]` Platforms to run on (default is all).
        log_level: `str` The log level to use None|App|Passthrough
        expect: `str` The expected result of the command Success|Failure|Any. (default is Success)
        redirect_stdout: `str` The file to redirect stdout to (prefer to parse the log file).
        timeout: `float` Number of seconds to run before sending a kill signal.
    """

    EFFECTIVE_TYPE = type if type != None else RUN_TYPE_DEFAULT
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
        name: `str` The name of the rule.
        target: `str` The name of the rule to kill.
        signal: `str` The signal to send to the target.
        help: `str` The help message for the rule.
        expect: `str` The expected result of the kill. (default is Success)
        deps: `[str]` Run rule dependencies.
        type: `str` See [run_add_exec()](#run_add_exec)
        platforms: `[str]` Platforms to run on (default is all).
    """

    EFFECTIVE_TYPE = type if type != None else RUN_TYPE_DEFAULT

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
        name: `str` The name of the rule.
        deps: `[str]` List of dependencies for the target.
        platforms: `[str]` List of platforms to build the target for (default is all).
        type: `str` See [run_add_exec()](#run_add_exec)
        help: `str` The help message for the rule.
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

def run_add_target_test(
        name,
        deps,
        help = None,
        platforms = None):
    """
    Adds a target to the workspace that `//:test` will depend on.

    This rule can be used to consolidate test dependencies into a single target.

    Args:
        name: `str` The name of the rule.
        deps: `[str]` List of dependencies for the target.
        platforms: `[str]` List of platforms to build the target for (default is all).
        help: `str` The help message for the rule.
    """
    run_add_target(
        name,
        deps = deps,
        help = help,
        type = RUN_TYPE_TEST,
        platforms = platforms,
    )

def run_add_target_precommit(
        name,
        deps,
        help = None,
        platforms = None):
    """
    Adds a target to the workspace that `//:pre-commit` will depend on.

    This rule can be used to consolidate PreCommit dependencies into a single target.

    Args:
        name: `str` The name of the rule.
        deps: `[str]` List of dependencies for the target.
        platforms: `[str]` List of platforms to build the target for (default is all).
        help: `str` The help message for the rule.
    """
    run_add_target(
        name,
        deps = deps,
        help = help,
        type = RUN_TYPE_PRECOMMIT,
        platforms = platforms,
    )

def run_add_to_all(
        name,
        deps):
    """
    Creates a target rule called name with deps and part of `:all`.

    Targets will run with `spaces run` or `spaces run //:all`.

    Args:
        name: `str` The name of the rule.
        deps: `[str]` List of dependencies to run with `spaces run`
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
        name: `str` The name of the rule.
        deps: `[str]` List of dependencies to run with `spaces run`
        version: `str` The version of the archive.
        source_directory: `str` The directory containing the source files to archive.
        includes: `[str]` List of globs to include in the archive.
        excludes: `[str]` List of globs to exclude from the archive.
        platform: `str` The platform to build the target for (default is all).

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

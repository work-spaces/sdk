"""
Spaces Shell (sh) Module

This module provides ergonomic wrappers around shell scripting operations. It supports:
- Simple command execution with full control over output handling
- Output capture (single string or lines)
- Exit code checking and error handling
- Optional working directory specification

All functions are designed to be easy to use while providing fine-grained control
when needed. By default, commands fail hard on non-zero exit codes, making it easy
to catch errors early.

Examples:
    # Run a command and capture its output
    output = sh_capture("git rev-parse HEAD")
    print(output)  # Single trimmed line

    # Get output as individual lines
    files = sh_lines("find . -name '*.txt'")
    for f in files:
        print(f)

    # Run a command and check exit code
    status = sh_exit_code("test -f config.json")
    if status == 0:
        print("Config exists")

    # Run a shell command with full output details
    result = sh_run("npm test", check=True)
    print("Status:", result["status"])
    print("Output:", result["stdout"])
"""

# ============================================================================
# Shell Command Execution
# ============================================================================

def sh_run(command: str, check: bool = False, cwd = None) -> dict:
    """
    Run a shell command and capture its complete output and status.

    This is the most flexible shell execution function. It runs the command through
    the platform shell (`/bin/sh -c` on Unix, `cmd.exe /C` on Windows) and returns
    the exit status, stdout, and stderr.

    Args:
        command: Shell command string to execute. This is passed directly to the
            platform shell, so pipes, redirections, and other shell features work.
        check: If True, raise an error when the command exits with non-zero status.
            If False (default), return the result regardless of exit code.
        cwd: Optional working directory for the command. If not specified, the
            command runs in the current working directory.

    Returns:
        dict: A result dictionary with the following keys:
            - status (int): Exit code of the command (0 = success)
            - stdout (str): Captured standard output
            - stderr (str): Captured standard error

    Raises:
        Error: If check=True and the command exits with non-zero status, or if
               the command cannot be executed.

    Examples:
        # Simple command execution
        result = sh_run("echo 'Hello, World!'")
        print(result["status"])   # 0
        print(result["stdout"])   # "Hello, World!\\n"

        # Use shell features (pipes, globbing, etc.)
        result = sh_run("ls *.py | wc -l")
        print("Python files:", result["stdout"])

        # Run with check=True to error on non-zero exit
        result = sh_run("cargo build", check=True)
        # Will raise error if build fails

        # Run in a specific directory
        result = sh_run("npm test", cwd="/path/to/project")
        print(result["stdout"])

        # Capture both stdout and stderr
        result = sh_run("some_command 2>&1")  # Merge stderr to stdout
        print(result["stdout"])
    """
    if cwd:
        return sh.run(command, check = check, cwd = cwd)
    else:
        return sh.run(command, check = check)

# ============================================================================
# Output Capture
# ============================================================================

def sh_capture(command: str, check: bool = True, cwd = None) -> str:
    """
    Run a shell command and return its trimmed stdout as a string.

    This is the most convenient function for capturing command output. The output
    is automatically trimmed of trailing newlines and whitespace. By default, it
    will raise an error if the command fails, making it safe for scripts where
    failure should abort.

    Args:
        command: Shell command string to execute.
        check: If True (default), raise an error when the command exits with
            non-zero status. Set to False to ignore command failures.
        cwd: Optional working directory for the command.

    Returns:
        str: The command's stdout, trimmed of trailing whitespace and newlines.

    Raises:
        Error: If check=True and the command exits with non-zero status, or if
               the command cannot be executed.

    Examples:
        # Get the current git branch
        branch = sh_capture("git rev-parse --abbrev-ref HEAD")
        print(f"Current branch: {branch}")

        # Get a single value
        count = int(sh_capture("find . -name '*.py' | wc -l"))
        print(f"Found {count} Python files")

        # List project version from a tool
        version = sh_capture("cargo metadata --format-version 1 | jq -r .packages[0].version")
        print(f"Version: {version}")

        # Ignore errors and use a default
        output = sh_capture("git rev-parse HEAD", check=False)
        if not output:
            print("Not in a git repository")

        # Get output from a command in a specific directory
        files = sh_capture("ls -1", cwd="/path/to/directory")
        print(files)
    """
    if cwd:
        return sh.capture(command, check = check, cwd = cwd)
    else:
        return sh.capture(command, check = check)

def sh_lines(command: str, check: bool = True, cwd = None) -> list:
    """
    Run a shell command and return its output split into individual lines.

    This function runs a command and automatically splits its stdout into lines,
    stripping trailing newlines. Empty trailing lines are not returned, making
    it convenient for iterating over command output.

    Args:
        command: Shell command string to execute.
        check: If True (default), raise an error when the command exits with
            non-zero status. Set to False to ignore command failures.
        cwd: Optional working directory for the command.

    Returns:
        list: A list of strings, one per line of output. Empty list if the
              command produces no output.

    Raises:
        Error: If check=True and the command exits with non-zero status, or if
               the command cannot be executed.

    Examples:
        # List files in a directory
        files = sh_lines("ls -1")
        for f in files:
            print(f"File: {f}")

        # Get git tags
        tags = sh_lines("git tag --list 'v*'")
        latest = tags[-1] if tags else None
        print(f"Latest tag: {latest}")

        # Filter and process output
        processes = sh_lines("ps aux | grep python | grep -v grep")
        print(f"Found {len(processes)} Python processes")
        for line in processes:
            print(line)

        # Find Python files and process each
        py_files = sh_lines("find . -name '*.py' -type f")
        for file in py_files:
            print(f"Processing: {file}")

        # Safely handle commands that might not produce output
        matching = sh_lines("grep -l 'pattern' *.txt", check=False)
        if matching:
            print(f"Found pattern in: {matching}")
        else:
            print("No matches found")
    """
    if cwd:
        return sh.lines(command, check = check, cwd = cwd)
    else:
        return sh.lines(command, check = check)

# ============================================================================
# Exit Code Checking
# ============================================================================

def sh_exit_code(command: str, cwd = None) -> int:
    """
    Run a shell command and return only its numeric exit code.

    This function is useful for conditional logic where you need to know whether
    a command succeeded or failed without capturing its output. Unlike other
    functions, this never raises an error for command failures - it only fails
    if the process cannot be spawned or waited on.

    Args:
        command: Shell command string to execute.
        cwd: Optional working directory for the command.

    Returns:
        int: The command's exit code (0 = success, non-zero = failure)

    Raises:
        Error: Only if the command cannot be spawned or the process cannot be waited on.

    Examples:
        # Check if a file exists using test command
        status = sh_exit_code("test -f config.json")
        if status == 0:
            print("Config file exists")
        else:
            print("Config file not found")

        # Check if a command is available
        status = sh_exit_code("command -v python3")
        if status == 0:
            print("Python 3 is available")

        # Conditional build
        status = sh_exit_code("git diff --quiet")
        if status != 0:
            print("Changes detected, rebuilding...")
            # Run build

        # Check multiple conditions
        status = sh_exit_code("grep -q 'pattern' file.txt")
        if status == 0:
            print("Pattern found")
        elif status == 1:
            print("Pattern not found")
        else:
            print(f"Search failed with status {status}")

        # Directory validation
        status = sh_exit_code("test -d /path/to/dir")
        is_dir = status == 0
    """
    if cwd:
        return sh.exit_code(command, cwd = cwd)
    else:
        return sh.exit_code(command)

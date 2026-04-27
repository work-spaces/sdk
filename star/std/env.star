"""
Environment and PATH manipulation builtins.

This module provides ergonomic access to environment variables, working directory management,
and PATH utilities for discovering executables on the system.

Example:
    # Get environment variables
    path = env_get("PATH")  # -> str (or empty string if not set)
    home = env_get("HOME", default="/tmp")  # -> str with fallback

    # Set and unset variables
    env_set("MY_VAR", "value")
    if env_has("MY_VAR"):
        env_unset("MY_VAR")

    # Work with directories
    original = env_cwd()  # Get current directory
    env_chdir("/tmp")  # Change to /tmp
    env_chdir(original)  # Change back

    # Find executables
    git_path = env_which("git")  # -> str or empty string
    python_paths = env_which_all("python")  # -> list[str]
"""

def env_get(name: str, default: str = "") -> str:
    """
    Gets an environment variable by name.

    If the variable is not set, returns the default value (empty string by default).
    This is the primary way to read environment variables in Starlark scripts.

    Args:
        name: The name of the environment variable (e.g., "PATH", "HOME", "USER")
        default: The value to return if the variable is not set. Defaults to empty string.

    Returns:
        The value of the environment variable as a string, or the default value if not set.

    Raises:
        Error: If the environment variable contains invalid UTF-8 (rare)

    Examples:
        >>> env_get("HOME")  # -> "/home/user" (or similar, platform-dependent)
        >>> env_get("NONEXISTENT")  # -> ""
        >>> env_get("NONEXISTENT", default="/tmp")  # -> "/tmp"
        >>> env_get("PATH")[:20]  # -> "/usr/local/bin:/usr/..." (Unix-like)
        >>> user = env_get("USER", default="unknown")
    """
    return env.get(name, default = default)

def env_set(name: str, value: str):
    """
    Sets an environment variable for the current process and child processes.

    This modifies the environment for the current process and any child processes
    it subsequently spawns. Does not affect parent processes or the system-wide environment.
    The change is temporary and only lasts for the duration of the process.

    Args:
        name: The name of the environment variable (e.g., "MY_VAR", "DEBUG")
        value: The value to set. Must be a string.

    Returns:
        None

    Examples:
        >>> env_set("CUSTOM_VAR", "hello")
        >>> env_get("CUSTOM_VAR")  # -> "hello"
        >>> env_set("DEBUG", "1")
        >>> env_set("CONFIG_PATH", "/etc/myapp.conf")
    """
    return env.set(name, value)

def env_unset(name: str):
    """
    Unsets (removes) an environment variable from the current process.

    This removes the variable from the current process and any child processes.
    Subsequent calls to env_get() will return the default value (or empty string).
    Does not affect parent processes or the system-wide environment.

    Args:
        name: The name of the environment variable to remove

    Returns:
        None

    Examples:
        >>> env_set("TEMP_VAR", "temporary")
        >>> env_has("TEMP_VAR")  # -> True
        >>> env_unset("TEMP_VAR")
        >>> env_get("TEMP_VAR")  # -> ""
        >>> env_has("TEMP_VAR")  # -> False
    """
    return env.unset(name)

def env_has(name: str) -> bool:
    """
    Checks whether an environment variable is present in the current process.

    Returns True if the variable exists (even if its value is an empty string).
    This is useful for checking if a variable has been explicitly set.

    Args:
        name: The name of the environment variable to check

    Returns:
        True if the variable is set in the environment, False otherwise

    Examples:
        >>> env_has("PATH")  # -> True (usually)
        >>> env_has("DEFINITELY_NOT_SET_VAR_12345")  # -> False
        >>> if env_has("CI"):
        ...     print("Running in CI environment")
        >>> if env_has("DEBUG"):
        ...     enable_debug_mode()
    """
    return env.has(name)

def env_all() -> dict[str, str]:
    """
    Returns all environment variables as a dictionary.

    Captures a snapshot of all environment variables at the time of the call.
    Modifications to the returned dictionary do not affect the process environment;
    use env_set() to change variables.

    Returns:
        A dictionary mapping environment variable names (strings) to their values (strings).
        For example: {"PATH": "/usr/bin:...", "HOME": "/home/user", "USER": "alice", ...}

    Examples:
        >>> vars = env_all()
        >>> len(vars) > 0  # -> True
        >>> "PATH" in vars  # -> True (usually)
        >>> vars["HOME"]  # -> "/home/user" (platform-dependent)
        >>> # Iterate over all variables
        >>> for name in vars:
        ...     print(f"{name}={vars[name]}")
        >>> # Find all variables starting with "RUST"
        >>> rust_vars = {k: v for k, v in env_all().items() if k.startswith("RUST")}
    """
    return env.all()

def env_cwd() -> str:
    """
    Returns the current working directory of the process.

    Returns the absolute path to the directory the process is currently operating in.
    This is affected by env_chdir() calls.

    Returns:
        An absolute path string to the current working directory.

    Raises:
        Error: If the current directory cannot be determined (e.g., if it has been deleted)

    Examples:
        >>> cwd = env_cwd()
        >>> len(cwd) > 0  # -> True
        >>> cwd.startswith("/")  # -> True (on Unix-like systems)
        >>> # Build paths relative to current directory
        >>> config_file = env_cwd() + "/config.yaml"
    """
    return env.cwd()

def env_chdir(path: str):
    """
    Changes the current working directory of the process.

    Changes the working directory for the current process and any subsequently
    spawned child processes. Does not affect parent processes.
    Use env_cwd() to get the current directory before changing to save a restoration point.

    Args:
        path: The directory path to change to. Can be absolute or relative.
              Supports both Unix-style ("/path/to/dir") and Windows-style ("C:\\path\\to\\dir") paths.

    Returns:
        None

    Raises:
        Error: If the directory does not exist or is not accessible

    Examples:
        >>> original = env_cwd()
        >>> env_chdir("/tmp")
        >>> env_cwd().endswith("tmp")  # -> True
        >>> env_chdir(original)  # Restore original directory
        >>> env_cwd() == original  # -> True
        >>> env_chdir("subdir")  # Works with relative paths too
        >>> env_chdir("..")  # Go up one level
    """
    return env.chdir(path)

def env_path_list() -> list[str]:
    """
    Splits the PATH environment variable into a list of directory entries.

    Parses the system PATH variable and returns each directory as a separate element.
    Handles platform-specific path separators (: on Unix/Linux/macOS, ; on Windows).
    Returns an empty list if PATH is not set or is empty.

    Returns:
        A list of directory paths in search order. Each entry is an absolute or relative path.
        Empty list if PATH is not set.

    Examples:
        >>> paths = env_path_list()
        >>> len(paths) > 0  # -> True (usually)
        >>> "/usr/bin" in paths or "C:\\Windows\\System32" in paths  # -> True (usually)
        >>> # Iterate through PATH directories
        >>> for directory in env_path_list():
        ...     print(f"Searching in: {directory}")
        >>> # Check if a directory is in PATH
        >>> "/usr/local/bin" in env_path_list()
    """
    return env.path_list()

def env_which(name: str) -> str:
    """
    Finds the first executable matching the given name in PATH.

    Searches through all directories in the PATH environment variable in order
    for an executable file with the given name. On Windows, also checks PATHEXT
    for recognized executable extensions (e.g., .COM, .EXE, .BAT, .CMD).

    If the name contains path separators (/ or \\), it's treated as a direct path
    and checked for executability rather than searching PATH.

    Args:
        name: The name of the executable to find (e.g., "git", "python", "node")
              Can also be a relative path (e.g., "./script.sh" or "subdir/tool")

    Returns:
        The full absolute path to the executable if found, empty string if not found.

    Examples:
        >>> git_path = env_which("git")
        >>> len(git_path) > 0  # -> True (if git is installed)
        >>> env_which("git").endswith("git") or env_which("git").endswith("git.exe")  # -> True
        >>> python_path = env_which("python")
        >>> "python" in python_path.lower() or "python" in python_path  # -> True (if found)
        >>> env_which("definitely-not-a-real-program-12345")  # -> ""
        >>> env_which("./local_script.sh")  # Check specific relative path
        >>> # Use in conditionals
        >>> if env_which("cargo"):
        ...     print("Rust is installed")
    """
    return env.which(name)

def env_which_all(name: str) -> list[str]:
    """
    Finds all executables matching the given name in PATH.

    Searches through all directories in the PATH environment variable
    and returns all matching executables in PATH order.
    Useful for finding all versions of an interpreter, tool, or script.
    Handles platform-specific executable extensions and permissions.

    On Unix-like systems, only returns files with executable permissions.
    On Windows, returns files with recognized executable extensions from PATHEXT.

    Args:
        name: The name of the executable to find (e.g., "python", "git", "node")

    Returns:
        A list of full absolute paths to all matching executables in PATH order.
        Returns empty list if no matches found.

    Examples:
        >>> pythons = env_which_all("python")
        >>> len(pythons) >= 0  # -> True
        >>> # Multiple Python versions might be installed
        >>> for python in pythons:
        ...     print(f"Found Python at: {python}")
        >>> git_paths = env_which_all("git")
        >>> len(git_paths) <= 1  # Usually just one git, but could be more
        >>> env_which_all("definitely-not-real-12345")  # -> []
        >>> # Check availability of interpreters
        >>> ruby_versions = env_which_all("ruby")
        >>> if ruby_versions:
        ...     use_ruby(ruby_versions[0])
    """
    return env.which_all(name)

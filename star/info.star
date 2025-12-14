"""
Spaces info built-ins
"""

def info_set_max_queue_count(max_queue_count):
    """
    Set the maximum number of jobs that can be queued.

    Args:
        max_queue_count: The maximum number of jobs that can be queued
    """
    info.set_max_queue_count(max_queue_count)

def info_set_minimum_version(version):
    """
    Set the minimum version of Spaces required to run the workflow

    Args:
        version: `str` The minimum version of Spaces required to run the workflow
    """
    info.set_minimum_version(version)

def info_get_cpu_count():
    """
    Get the number of CPUs available

    Returns:
        The number of CPUs available
    """
    return info.get_cpu_count()

def info_get_path_to_store():
    """
    Gets the path to the spaces store

    Returns:
        The path to the store
    """
    return info.get_path_to_store()

def info_is_platform_x86_64():
    """
    Check if the platform is x86_64

    Returns:
        True if the platform is x86_64, False otherwise
    """
    return info.is_platform_x86_64()

def info_is_platform_aarch64():
    """
    Check if the platform is aarch64

    Returns:
        True if the platform is aarch64, False otherwise
    """
    return info.is_platform_aarch64()

def info_is_platform_linux():
    """
    Check if the platform is Linux

    Returns:
        True if the platform is Linux, False otherwise
    """
    return info.is_platform_linux()

def info_is_platform_macos():
    """
    Check if the platform is macOS

    Returns:
        True if the platform is macOS, False otherwise
    """
    return info.is_platform_macos()

def info_is_platform_windows():
    """
    Check if the platform is Windows

    Returns:
        True if the platform is Windows, False otherwise
    """
    return info.is_platform_windows()

def info_get_platform_name():
    """
    Get the platform name

    Returns:
        The platform name
    """
    return info.get_platform_name()

def info_get_supported_platforms():
    """
    Get the supported platforms

    Returns:
        The supported platforms
    """
    return info.get_supported_platforms()

def info_get_path_to_spaces_tools():
    """
    Get the path to the Spaces tools folder

    Returns:
        The path to the Spaces tools folder
    """
    return info.get_path_to_spaces_tools()

def info_parse_log_file(path):
    """
    Parses a log file

    Args:
        path: `str` path to the log file

    Returns:
        dict: with members `header` and lines
    """
    return info.parse_log_file(path)

def info_set_required_semver(required):
    """
    Set the required `spaces` semver for the workflow

    Args:
        required: `str` The required semver for the workflow
    """
    info.set_required_semver(required)

def info_is_ci():
    """
    Check if the workflow is running in a CI environment.

    Returns:
        True if `--ci` is passed when running `spaces`, False otherwise
    """
    return info.is_ci()

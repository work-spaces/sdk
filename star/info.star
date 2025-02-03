"""
Spaces info built-ins
"""

def info_set_max_queue_count(max_queue_count):
    """
    Set the maximum number of jobs that can be queued

    Args:
        max_queue_count: The maximum number of jobs that can be queued
    """
    info.set_max_queue_count(max_queue_count)

def info_set_minimum_version(version):
    """
    Set the minimum version of Spaces required to run the workflow

    Args:
        version: The minimum version of Spaces required to run the workflow
    """
    info.set_minimum_version(version)

def info_get_absolute_path_to_workspace():
    """
    Get the absolute path to the workspace

    Returns:
        The absolute path to the workspace
    """
    return info.get_absolute_path_to_workspace()

def info_get_path_to_checkout():
    """
    Get the path in the workspace where the current module is located

    Returns:
        The path to the checked out repo or archive
    """
    return info.get_path_to_checkout()

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

def info_get_env_var(name):
    """
    Get the value of an environment variable

    Args:
        name: The name of the environment variable

    Returns:
        The value of the environment variable
    """
    return info.get_env_var(name)

def info_is_env_var_set(name):
    """
    Check if an environment variable is set

    Args:
        name: The name of the environment variable

    Returns:
        True if the environment variable is set, False otherwise
    """
    return info.is_env_var_set(name)

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

def info_is_workspace_reproducible():
    """
    Check if the workspace is reproducible

    Returns:
        True if the workspace is reproducible, False otherwise
    """
    return info.is_workspace_reproducible()

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
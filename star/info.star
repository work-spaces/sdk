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

def info_get_path_to_log_file(name):
    """
    Gets the path to the log file for a given target.

    The log file location changes on every run.

    Args:
        name: The name of the rule

    Returns:
        The relative workspace path to the log file
    """

    return info.get_path_to_log_file(name)

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

def _get_member_requirement(url, rev = None, semver = None):
    version_requirment = {}
    if rev != None:
        version_requirment = {"required": {"Revision": rev}}
    elif semver != None:
        version_requirment = {"required": {"SemVer": semver}}
    return {
        "url": url,
    } | version_requirment

def _is_path_to_workspace_member_available(
        url,
        rev = None,
        semver = None):
    info_set_minimum_version(">0.12.6")
    return info.is_path_to_workspace_member_available(
        member = _get_member_requirement(url, rev, semver),
    )

def _get_path_to_workspace_member(
        url,
        rev = None,
        semver = None):
    info_set_minimum_version(">0.12.6")
    return info.get_path_to_workspace_member(
        member = _get_member_requirement(url, rev, semver),
    )

def info_get_path_to_member_with_semver(
        url,
        semver):
    """
    Get the path to a workspace member.

    If the the specified requirement is not found, the program will exit with an error.
    Not all workspace members have versions. The version is set manually during checkout
    or pulled from the git rev (tag).

    Args:
        url: The url of the workspace member
        semver: The semver requiement assuming the member has a version

    Returns:
        The path to the workspace member.
    """
    return _get_path_to_workspace_member(
        url = url,
        semver = semver,
    )

def info_get_path_to_member_with_rev(
        url,
        rev):
    """
    Gets the path to a workspace member with the specified revision.

    If the the specified requirement is not found, the program will exit with an error.

    Args:
        url: The url of the workspace member
        rev: the git or sha256 hash

    Returns:
        The path to the workspace member.
    """
    return _get_path_to_workspace_member(
        url = url,
        rev = rev,
    )

def info_check_member_semver(url, semver):
    """
    Checks if the workspace satifies a requirement

    Args:
        url: The url of the workspace member
        semver: The semver requiement assuming the member has a version

    Returns:
        True if the workspace member is found satisfying semver, False otherwise
    """

    return _is_path_to_workspace_member_available(url, rev = None, semver = semver)

def info_assert_member_semver(url, semver):
    """
    Fails if the workspace does not satifies a requirement

    Args:
        url: The url of the workspace member
        semver: The semver requiement assuming the member has a version

    Returns:
        True if the workspace member is found satisfying semver, False otherwise
    """

    IS_AVAILABLE = _is_path_to_workspace_member_available(url, semver = semver)
    if not IS_AVAILABLE:
        info.abort("The workspace member at {} does not satisfy the semver requirement {}".format(url, semver))

def info_assert_member_revision(url, rev):
    """
    Checks if the workspace satifies a requirement

    Args:
        url: The url of the workspace member
        rev: git/sha256 hash

    Returns:
        Aborts if the requirement is not satisfied
    """

    IS_AVAILABLE = _is_path_to_workspace_member_available(url, rev = rev)
    if not IS_AVAILABLE:
        info.abort("The workspace member at {} does not satisfy the revision requirement {}".format(url, rev))

def info_check_member_revision(url, rev):
    """
    Checks if the workspace satifies a requirement

    Args:
        url: The url of the workspace member
        rev: git/sha256 hash

    Returns:
        True if the workspace member is found at the specified rev, False otherwise
    """

    return _is_path_to_workspace_member_available(url, rev = rev)
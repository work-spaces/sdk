"""
Spaces workspace built-ins

Note: This file is name ws.star instead of workspace.star because of how
the linter treats starlark files with workspace in the name.

"""

WORKSPACE_SYSROOT = "sysroot"

def workspace_get_absolute_path():
    """
    Get the absolute path to the workspace

    Returns:
        The absolute path to the workspace
    """
    return workspace.get_absolute_path()

def workspace_get_path_to_checkout():
    """
    Get the path in the workspace where the current module is located

    Returns:
        The path to the checked out repo or archive
    """
    return workspace.get_path_to_checkout()

def workspace_get_path_to_log_file(name):
    """
    Gets the path to the log file for a given target.

    The log file location changes on every run.

    Args:
        name: The name of the rule

    Returns:
        The relative workspace path to the log file
    """

    return workspace.get_path_to_log_file(name)

def workspace_get_cpu_count():
    """
    Get the number of CPUs available

    Use info_get_cpu_count(). This will be removed in a future release.

    Returns:
        The number of CPUs available
    """
    return workspace.get_cpu_count()

def workspace_get_env_var(name):
    """
    Get the value of an environment variable

    Args:
        name: The name of the environment variable

    Returns:
        The value of the environment variable
    """
    return workspace.get_env_var(name)

def workspace_is_env_var_set(name):
    """
    Check if an environment variable is set

    Args:
        name: The name of the environment variable

    Returns:
        True if the environment variable is set, False otherwise
    """
    return workspace.is_env_var_set(name)

def workspace_is_reproducible():
    """
    Check if the workspace is reproducible

    If any repos are on a branch rather than a commit, this will return False.
    Use a lock file (see `--create-lock-file`) to ensure reproducibility.

    Returns:
        True if the workspace is reproducible, False otherwise
    """
    return workspace.is_reproducible()

def _get_member_requirement(url, rev = None, semver = None):
    version_requirment = {}
    if rev != None:
        version_requirment = {"required": {"Revision": rev}}
    elif semver != None:
        version_requirment = {"required": {"SemVer": semver}}
    return {
        "url": url,
    } | version_requirment

def _is_path_to_member_available(
        url,
        rev = None,
        semver = None):
    info.set_minimum_version("0.14.0")
    return workspace.is_path_to_member_available(
        member = _get_member_requirement(url, rev, semver),
    )

def _get_path_to_member(
        url,
        rev = None,
        semver = None):
    info.set_minimum_version("0.14.0")
    return workspace.get_path_to_member(
        member = _get_member_requirement(url, rev, semver),
    )

def workspace_get_path_to_member_with_semver(
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
    return _get_path_to_member(
        url = url,
        semver = semver,
    )

def workspace_get_path_to_member_with_rev(
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
    return _get_path_to_member(
        url = url,
        rev = rev,
    )

def workspace_check_member_semver(url, semver):
    """
    Checks if the workspace satifies a requirement

    Args:
        url: The url of the workspace member
        semver: The semver requiement assuming the member has a version

    Returns:
        True if the workspace member is found satisfying semver, False otherwise
    """

    return _is_path_to_member_available(url, rev = None, semver = semver)

def workspace_assert_member_semver(url, semver):
    """
    Fails if the workspace does not satifies a requirement

    Args:
        url: The url of the workspace member
        semver: The semver requiement assuming the member has a version

    Returns:
        True if the workspace member is found satisfying semver, False otherwise
    """

    IS_AVAILABLE = _is_path_to_member_available(url, semver = semver)
    if not IS_AVAILABLE:
        info.abort("The workspace member at {} does not satisfy the semver requirement {}".format(url, semver))

def workspace_assert_member_revision(url, rev):
    """
    Checks if the workspace satifies a requirement

    Args:
        url: The url of the workspace member
        rev: git/sha256 hash

    Returns:
        Aborts if the requirement is not satisfied
    """

    IS_AVAILABLE = _is_path_to_member_available(url, rev = rev)
    if not IS_AVAILABLE:
        info.abort("The workspace member at {} does not satisfy the revision requirement {}".format(url, rev))

def workspace_check_member_revision(url, rev):
    """
    Checks if the workspace satifies a requirement

    Args:
        url: The url of the workspace member
        rev: git/sha256 hash

    Returns:
        True if the workspace member is found at the specified rev, False otherwise
    """

    return _is_path_to_member_available(url, rev = rev)

def workspace_get_build_archive_info(name, archive):
    """
    Gets the archive info the specified rule and archive

    Args:
        name: rule name to get info for
        archive: archive object containing details of how to create the archive
    """
    return workspace.get_build_archive_info(
        rule_name = name,
        archive = archive
    )
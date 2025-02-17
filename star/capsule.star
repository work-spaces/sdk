"""
Spaces starlark functions for creating and working with capsules
"""

load(
    "checkout.star",
    "CHECKOUT_TYPE_OPTIONAL",
    "checkout_add_oras_archive",
    "checkout_add_platform_archive",
    "checkout_add_repo",
)
load("run.star", "run_add_target")
load("std/fs.star", "fs_exists")
load("oras.star", "oras_add_publish_archive")
load("gh.star", "gh_add_publish_archive")
load("rpath.star", "rpath_update_macos_install_dir")

_DOMAIN = "domain"
_OWNER = "owner"
_REPO = "repo"

_DESCRIPTOR = "descriptor"
_OPTIONS = "options"

_OPTION_INSTALL_PATH = "install_path"
_OPTION_IS_USE_SOURCE = "is_use_source"
_OPTION_ORAS_URL = "oras_url"
_OPTION_GH_DEPLOY_REPO = "gh_deploy_repo"
_OPTION_VERSION = "version"
_OPTION_REV = "rev"
_OPTION_ARCHIVE_SUFFIX = "archive_suffix"

def _create_descriptor(
        domain,
        owner,
        repo):
    return {
        _DOMAIN: domain,
        _OWNER: owner,
        _REPO: repo,
    }

def _create_options(
        version,
        source_revision = None,
        archive_suffix = "tar.xz",
        install_path = None,
        oras_url = None,
        gh_deploy_repo = None,
        is_use_source = False):
    EFFECTIVE_SOURCE_REVISION = source_revision if source_revision != None else "v{}".format(version)
    return {
        _OPTION_VERSION: version,
        _OPTION_REV: EFFECTIVE_SOURCE_REVISION,
        _OPTION_IS_USE_SOURCE: is_use_source,
        _OPTION_INSTALL_PATH: install_path,
        _OPTION_ORAS_URL: oras_url,
        _OPTION_GH_DEPLOY_REPO: gh_deploy_repo,
        _OPTION_ARCHIVE_SUFFIX: archive_suffix,
    }

def _create(
        descriptor,
        options):
    return {
        _DESCRIPTOR: descriptor,
        _OPTIONS: options,
    }

def _get_option(
        capsule,
        option):
    return capsule[_OPTIONS][option]

def _to_url(capsule):
    DESCRIPTOR = capsule[_DESCRIPTOR]
    return "https://{}/{}/{}".format(
        DESCRIPTOR[_DOMAIN],
        DESCRIPTOR[_OWNER],
        DESCRIPTOR[_REPO],
    )

def _to_workspace_path(capsule):
    DESCRIPTOR = capsule[_DESCRIPTOR]
    return "{}/{}/{}".format(
        DESCRIPTOR[_DOMAIN],
        DESCRIPTOR[_OWNER],
        DESCRIPTOR[_REPO],
    )

def _to_name(capsule):
    DESCRIPTOR = capsule[_DESCRIPTOR]
    return "{}-{}-{}{}".format(
        DESCRIPTOR[_DOMAIN],
        DESCRIPTOR[_OWNER],
        DESCRIPTOR[_REPO],
        "-exp",
    )

def capsule_get_rule_name(capsule, suffix):
    return "{}_{}".format(_to_name(capsule), suffix)

def _to_oras_artifact(capsule):
    capsule_name = _to_name(capsule)
    return "{}-{}".format(capsule_name, info.get_platform_name())

def _to_oras_label(capsule):
    ORAS_ARTIFACT = _to_oras_artifact(capsule)
    URL = _get_option(capsule, _OPTION_ORAS_URL)

    #oras_label = "{}:{}".format(_descriptor_to_oras_label(url, capsule), "{}-{}".format(version, digest))
    return "{}/{}".format(URL, ORAS_ARTIFACT)

def capsule_get_domain(capsule):
    return capsule[_DESCRIPTOR][_DOMAIN]

def capsule_get_owner(capsule):
    return capsule[_DESCRIPTOR][_OWNER]

def capsule_get_repo(capsule):
    return capsule[_DESCRIPTOR][_REPO]

def capsule_get_version(capsule):
    return capsule[_OPTIONS][_OPTION_VERSION]

def capsule_get_install_path(capsule):
    return capsule[_DESCRIPTOR][_OPTION_INSTALL_PATH]

def capsule_can_publish(capsule):
    return _get_option(capsule, _OPTION_ORAS_URL) != None or _get_option(capsule, _OPTION_GH_DEPLOY_REPO) != None

def capsule_declare(
        domain,
        owner,
        repo,
        version,
        source_revision = None,
        archive_suffix = "tar.xz",
        install_path = None,
        oras_url = None,
        gh_deploy_repo = None,
        is_use_source = False):
    """
    Declare a capsule.

    Args:
        domain: The domain of the capsule
        owner: The owner of the capsule
        repo: The repo of the capsule
        version: The version of the capsule
        source_revision: The revision of the source code
        archive_suffix: The suffix of the archive
        install_path: The install path of the capsule
        oras_url: The oras url of the capsule
        gh_deploy_repo: The github deploy repo of the capsule
        is_use_source: Whether to use the source code

    Returns:
        dict: The capsule
    """

    DESCRIPTOR = _create_descriptor(domain, owner, repo)
    OPTIONS = _create_options(
        version,
        source_revision,
        archive_suffix = archive_suffix,
        install_path = install_path,
        oras_url = oras_url,
        gh_deploy_repo = gh_deploy_repo,
        is_use_source = is_use_source,
    )
    capsule = _create(DESCRIPTOR, OPTIONS)
    if install_path == None:
        capsule[_OPTIONS][_OPTION_INSTALL_PATH] = "build/{}/install".format(_to_name(capsule))
    return capsule

def _add_checkout_oras(capsule):
    """
    Add the oras capsule to the sysroot.

    If the release is not available None is returned. Otherwise, a platform archive dictionary is returned.

    Args:
        capsule: return value of capsule()

    Returns:
        dict: with the platform and the url to download the gh executable
    """

    ORAS_COMMAND = "{}/sysroot/bin/oras".format(info.get_path_to_spaces_tools())
    ORAS_LABEL = _to_oras_label(capsule)

    # Check oras to see if the executable is available
    check_release = process.exec({
        "command": ORAS_COMMAND,
        "args": [
            "manifest",
            "fetch",
            ORAS_LABEL,
        ],
    })

    if check_release["status"] != 0:
        # the release is not available
        return None

    if not json.is_string_json(check_release["stdout"]):
        # manifest fetch doesn't return an error on failure
        # but is doesn't return a json string
        return None

    PUBLISH_NAME = capsule_get_rule_name(capsule, "publish")
    checkout_add_oras_archive(
        PUBLISH_NAME,
        url = _get_option(capsule, _OPTION_ORAS_URL),
        artifact = _to_oras_artifact(capsule),
        tag = _get_option(capsule, _OPTION_VERSION),
        add_prefix = _get_option(capsule, _OPTION_INSTALL_PATH),
    )

    return PUBLISH_NAME

def _add_checkout_gh(capsule):
    """
    Add the gh executable to the sysroot.

    If the release is not available None is returned. Otherwise, a platform archive dictionary is returned.

    Args:
        capsule: return value of capsule()

    Returns:
        str: the name of checkout rule for the platform archive
    """

    # https://github.com/work-spaces/tools/releases/download/ninja-v1.12.1/ninja-v1.12.1-macos-x86_64.sha256.txt
    digest = info.get_workspace_short_digest()
    capsule_name = _to_name(capsule)
    release_name = "{}-v{}".format(capsule_name, digest)
    gh_command = "{}/sysroot/bin/gh".format(info.get_path_to_spaces_tools())

    GH_DEPLOY_REPO = _get_option(capsule, _OPTION_GH_DEPLOY_REPO)

    # Check gh to see if the executable is available
    check_release = process.exec({
        "command": gh_command,
        "args": [
            "release",
            "view",
            release_name,
            "--repo={}".format(GH_DEPLOY_REPO),
            "--json=assets",
        ],
    })

    if check_release["status"] != 0:
        # the release is not available
        return None

    # check to see if the release is available for the platform
    platform = info.get_platform_name()
    url = "{}/releases/download/{}/{}-{}".format(GH_DEPLOY_REPO, release_name, release_name, platform)

    SUFFIX = _get_option(capsule, _OPTION_ARCHIVE_SUFFIX)
    platform_url = "{}.{}".format(url, SUFFIX)
    platform_sha256_url = "{}.sha256.txt".format(url)

    assets_root = json.string_to_dict(check_release["stdout"])
    assets = assets_root["assets"]

    # Ensure that the platform assets are both available
    platform_url_is_found = False
    platform_sha256_url_is_found = False
    for asset in assets:
        if asset["url"] == platform_url:
            platform_url_is_found = True
        if asset["url"] == platform_sha256_url:
            platform_sha256_url_is_found = True

    if not platform_url_is_found or not platform_sha256_url_is_found:
        return None

    PUBLISH_NAME = capsule_get_rule_name(capsule, "publish")
    checkout_add_platform_archive(
        PUBLISH_NAME,
        platforms = {
            platform: {
                "url": platform_url,
                "sha256": platform_sha256_url,
                "link": "Hard",
                "add_prefix": _get_option(capsule, _OPTION_INSTALL_PATH),
            },
        },
    )

    return PUBLISH_NAME

def _add_archive(capsule):
    ORAS_URL = _get_option(capsule, _OPTION_ORAS_URL)
    GH_DEPLOY_REPO = _get_option(capsule, _OPTION_GH_DEPLOY_REPO)
    if ORAS_URL != None:
        return _add_checkout_oras(capsule)
    elif GH_DEPLOY_REPO != None:
        return _add_checkout_gh(capsule)

    return None

def capsule_get_run_name(capsule):
    """
    Gets the name of the run rule associated with this capsule.

    Dependents should depend on this rule to build the capsule.

    Args:
        capsule: return value of capsule()
    Returns:
        str: the name of the run rule
    """
    return capsule_get_rule_name(capsule, "run")

def capsule_get_publish_name(capsule):
    """
    Gets the name of the run rule associated with this capsule.

    Dependents should depend on this rule to build the capsule.

    Args:
        capsule: return value of capsule()
    Returns:
        str: the name of the run rule
    """
    return capsule_get_rule_name(capsule, "publish")

def capsule_get_workspace_path(capsule):
    """
    Gets the name of the run rule associated with this capsule.

    Dependents should depend on this rule to build the capsule.

    Args:
        capsule: return value of capsule()
    Returns:
        str: the name of the run rule
    """
    return _to_workspace_path(capsule)

def capsule_get_install_path(capsule):
    """
    Gets the name of the run rule associated with this capsule.

    Dependents should depend on this rule to build the capsule.

    Args:
        capsule: return value of capsule()
    Returns:
        str: the name of the run rule
    """
    return _get_option(capsule, _OPTION_INSTALL_PATH)

def capsule_get_checkout_type(capsule, run_name):
    """
    This will either download pre-built binaries matching the capsule or checkout the source to build the capsule.

    Args:
        capsule: return value of capsule()
        run_name: the name of the optional run target to activate if pre-built binaries are not available

    Returns:
        The name of the run target that dependents should use to build from source or use the pre-built binaries
    """

    ORAL_URL = _get_option(capsule, _OPTION_ORAS_URL)
    GH_DEPLOY_REPO = _get_option(capsule, _OPTION_GH_DEPLOY_REPO)
    IS_USE_SOURCE = _get_option(capsule, _OPTION_IS_USE_SOURCE)

    is_activate_checkout = False
    platform_archive_rule = None

    # Has the source already been checked out?
    IS_CHECKED_OUT = fs_exists(capsule_get_workspace_path(capsule))

    # Check the platform install location to see if this has already been downloaded
    IS_DOWNLOADED = False
    IS_CHECK_PLATFORM = not IS_USE_SOURCE and not IS_CHECKED_OUT and not IS_DOWNLOADED

    if IS_CHECK_PLATFORM and (ORAL_URL != None or GH_DEPLOY_REPO != None):
        platform_archive_rule = _add_archive(capsule)

    # no platform archive ready -- need to checkout the source repo
    if platform_archive_rule == None:
        is_activate_checkout = True

    run_add_target(
        capsule_get_run_name(capsule),
        deps = [run_name] if is_activate_checkout else [],
    )

    return None if is_activate_checkout else CHECKOUT_TYPE_OPTIONAL

def capsule_checkout_add_repo(
        capsule,
        run_name,
        clone = "Blobless"):
    GIT_URL = _to_url(capsule)
    checkout_add_repo(
        capsule_get_workspace_path(capsule),
        url = GIT_URL,
        type = capsule_get_checkout_type(capsule, run_name),
        rev = _get_option(capsule, _OPTION_REV),
        clone = clone,
    )

def _oras_publish(
        capsule,
        deps):
    oras_add_publish_archive(
        capsule_get_publish_name(capsule),
        url = _get_option(capsule, _OPTION_ORAS_URL),
        deploy_repo = _get_option(capsule, _OPTION_GH_DEPLOY_REPO),
        artifact = _to_oras_artifact(capsule),
        tag = _get_option(capsule, _OPTION_VERSION),
        input = _get_option(capsule, _OPTION_INSTALL_PATH),
        deps = deps,
        suffix = _get_option(capsule, _OPTION_ARCHIVE_SUFFIX),
    )

def _gh_publish(
        capsule,
        deps):
    gh_add_publish_archive(
        capsule_get_publish_name(capsule),
        input = _get_option(capsule, _OPTION_INSTALL_PATH),
        version = _get_option(capsule, _OPTION_VERSION),
        deploy_repo = _get_option(capsule, _OPTION_GH_DEPLOY_REPO),
        suffix = _get_option(capsule, _OPTION_ARCHIVE_SUFFIX),
        deps = deps,
    )

def capsule_publish(
        capsule,
        deps):
    """
    Relocate the capsule and publish to github.

    Args:
        capsule: return value of capsule()
        deps: The dependencies of the capsule
    """

    RELOCATE_RULE_NAME = capsule_get_rule_name(capsule, "relocate")
    rpath_update_macos_install_dir(
        RELOCATE_RULE_NAME,
        install_path = _get_option(capsule, _OPTION_INSTALL_PATH),
        deps = deps,
    )

    if _get_option(capsule, _OPTION_ORAS_URL) != None:
        _oras_publish(
            capsule,
            deps = [RELOCATE_RULE_NAME],
        )
    elif _get_option(capsule, _OPTION_GH_DEPLOY_REPO) != None:
        _gh_publish(
            capsule,
            deps = [RELOCATE_RULE_NAME],
        )
    else:
        checkout.abort("Must specify either `oras_url` or `gh_deploy_repo`")

def capsule_publish_add_run_target(capsule, run_name):
    """
    Add the checkout and run if the install path does not exist

    Args:
        capsule: return value of capsule()
        run_name: The run rule that will build and install (not publish) the target
    """

    NAME = _to_name(capsule)
    run_add_target(
        "{}_run".format(NAME),
        deps = [run_name],
    )

def capsule_get_deps(capsule_deps):
    return [
        capsule_get_run_name(dep)
        for dep in capsule_deps
    ]

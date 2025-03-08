"""
Spaces starlark functions for creating and working with capsules
"""

load(
    "checkout.star",
    "CHECKOUT_TYPE_OPTIONAL",
    "checkout_add_oras_archive",
    "checkout_add_platform_archive",
    "checkout_add_repo",
    "checkout_update_asset"
)
load("run.star", "run_add_target")
load("info.star", "info_get_platform_name")
load("ws.star", "workspace_get_absolute_path")
load("std/fs.star", "fs_exists", "fs_read_json")
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
_OPTION_SOURCE_DIRECTORY = "source_directory"
_OPTION_PLATFORM_NAME = "platform_name"
_OPTION_CAPSULE_DEPS = "capsule_deps"

_STATUS_JSON = "capsules.spaces.json"
_STATUS_DOWNLOADED = "downloaded"
_STATUS_SOURCE = "source"

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
        source_directory,
        rev,
        archive_suffix,
        install_path,
        oras_url,
        platform_name,
        gh_deploy_repo,
        capsule_deps,
        is_use_source):
    return {
        _OPTION_VERSION: version,
        _OPTION_REV: rev,
        _OPTION_IS_USE_SOURCE: is_use_source,
        _OPTION_INSTALL_PATH: install_path,
        _OPTION_ORAS_URL: oras_url,
        _OPTION_GH_DEPLOY_REPO: gh_deploy_repo,
        _OPTION_ARCHIVE_SUFFIX: archive_suffix,
        _OPTION_SOURCE_DIRECTORY: source_directory,
        _OPTION_PLATFORM_NAME: platform_name,
        _OPTION_CAPSULE_DEPS: capsule_deps,
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
    """
    Get the rule name for the capsule.

    Args:
        capsule: return value of capsule_declare()
        suffix: The suffix to append to the rule name

    Returns:
        `str`: The rule name
    """
    return "{}_{}".format(_to_name(capsule), suffix)

def _to_oras_artifact(capsule):
    capsule_name = _to_name(capsule)
    return "{}-{}".format(capsule_name, _get_option(capsule, _OPTION_PLATFORM_NAME))

def _to_oras_label(capsule):
    ORAS_ARTIFACT = _to_oras_artifact(capsule)
    URL = _get_option(capsule, _OPTION_ORAS_URL)
    VERSION = _get_option(capsule, _OPTION_VERSION)
    #oras_label = "{}:{}".format(_descriptor_to_oras_label(url, capsule), "{}-{}".format(version, digest))
    return "{}/{}:{}".format(URL, ORAS_ARTIFACT, VERSION)

def capsule_get_domain(capsule):
    """
    Get the domain of the capsule.

    Args:
        capsule: return value of [capsule_declare()](#capsule_declare)
    
    Returns:
        `str`: The domain of the capsule
    """
    return capsule[_DESCRIPTOR][_DOMAIN]

def capsule_get_owner(capsule):
    """
    Get the owner of the capsule.

    Args:
        capsule: return value of [capsule_declare()](#capsule_declare)
    
    Returns:
        `str`: The owner of the capsule
    """
    return capsule[_DESCRIPTOR][_OWNER]

def capsule_get_repo(capsule):
    """
    Get the repo of the capsule.

    Args:
        capsule: return value of [capsule_declare()](#capsule_declare)
    
    Returns:
        `str`: The repo of the capsule
    """
    return capsule[_DESCRIPTOR][_REPO]

def capsule_get_version(capsule):
    """
    Get the version of the capsule.

    Args:
        capsule: return value of [capsule_declare()](#capsule_declare)

    Returns:
        `str`: The version of the capsule
    """
    return _get_option(capsule, _OPTION_VERSION)

def capsule_get_install_path(capsule):
    """
    Get the install path of the capsule.

    Args:
        capsule: return value of [capsule_declare()](#capsule_declare)

    Returns:
        `str`: The install path of the capsule
    """
    return _get_option(capsule, _OPTION_INSTALL_PATH)

def capsule_get_build_path(capsule):
    """
    Get the build path of the capsule.

    Args:
        capsule: return value of [capsule_declare()](#capsule_declare)
    
    Returns:
        `str` The build path of the capsule
    """
    return "build/{}".format(_to_name(capsule))

def capsule_can_publish(capsule):
    """
    Check if the capsule can be published.

    Args:
        capsule: return value of [capsule_declare()](#capsule_declare)

    Returns:
        `bool` True if the capsule can be published
    """
    return _get_option(capsule, _OPTION_ORAS_URL) != None or _get_option(capsule, _OPTION_GH_DEPLOY_REPO) != None

def capsule_declare(
        domain,
        owner,
        repo,
        version,
        capsule_deps = [],
        source_directory = None,
        rev = None,
        archive_suffix = "tar.xz",
        install_path = None,
        oras_url = None,
        platform_name = None,
        gh_deploy_repo = None,
        is_use_source = False):
    """
    Declare a capsule.

    Args:
        domain: `str` The domain of the capsule
        owner:`str`  The owner of the capsule
        repo: `str` The repo of the capsule
        version: `str` The version of the capsule
        capsule_deps: `[dict]` The dependencies of the capsule (as returned by another call to capsule_declare())
        source_directory: `str` location of the source directory (default is infer from domain/org/repo)
        rev: `str` The revision of the source code. If empty, the value is version with a `v` prefixed.
        archive_suffix: `str` The suffix of the archive
        install_path: `str` The install path of the capsule
        oras_url: `str` The oras url of the capsule (None to deploy to gh releases)
        gh_deploy_repo: `str` The github deploy repo of the capsule (None to skip deployment).
        is_use_source: `bool` Whether to use the source code or check for a binary release
        platform_name: `str` Platform name of the capsule (default is infer from the host platform)

    Returns:
        `dict` The capsule definition
    """

    EFFECTIVE_REV = rev if rev != None else "v{}".format(version)
    EFFECTIVE_PLATFORM = platform_name if platform_name != None else info_get_platform_name()

    DESCRIPTOR = _create_descriptor(domain, owner, repo)
    OPTIONS = _create_options(
        version,
        rev = EFFECTIVE_REV,
        archive_suffix = archive_suffix,
        install_path = install_path,
        oras_url = oras_url,
        gh_deploy_repo = gh_deploy_repo,
        is_use_source = is_use_source,
        source_directory = source_directory,
        platform_name = EFFECTIVE_PLATFORM,
        capsule_deps = capsule_deps,
    )
    capsule = _create(DESCRIPTOR, OPTIONS)
    if install_path == None:
        capsule[_OPTIONS][_OPTION_INSTALL_PATH] = "build/install/{}".format(_to_name(capsule))
    if source_directory == None:
        capsule[_OPTIONS][_OPTION_SOURCE_DIRECTORY] = _to_workspace_path(capsule)
    return capsule

def _add_checkout_oras(capsule):
    """
    Add the oras capsule to the sysroot.

    If the release is not available None is returned. Otherwise, a platform archive dictionary is returned.

    Args:
        capsule: return value of capsule_declare()

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

    CHECKOUT_NAME = capsule_get_rule_name(capsule, "checkout")
    checkout_add_oras_archive(
        CHECKOUT_NAME,
        url = _get_option(capsule, _OPTION_ORAS_URL),
        artifact = _to_oras_artifact(capsule),
        tag = _get_option(capsule, _OPTION_VERSION),
        add_prefix = _get_option(capsule, _OPTION_INSTALL_PATH),
    )

    return CHECKOUT_NAME

def _add_checkout_gh(capsule):
    """
    Add the gh executable to the sysroot.

    If the release is not available None is returned. Otherwise, a platform archive dictionary is returned.

    Args:
        capsule: return value of capsule_declare()

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
    platform = _get_option(capsule, _OPTION_PLATFORM_NAME)
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

    CHECKOUT_NAME = capsule_get_rule_name(capsule, "platform_archive")
    checkout_add_platform_archive(
        CHECKOUT_NAME,
        platforms = {
            platform: {
                "url": platform_url,
                "sha256": platform_sha256_url,
                "link": "Hard",
                "add_prefix": _get_option(capsule, _OPTION_INSTALL_PATH),
            },
        },
    )

    return CHECKOUT_NAME

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
        capsule: return value of capsule_declare()
    Returns:
        str: the name of the run rule
    """
    return capsule_get_rule_name(capsule, "run")

def capsule_get_publish_name(capsule):
    """
    Gets the name of the publish rule associated with this capsule.

    Args:
        capsule: return value of capsule_declare()
    Returns:
        str: the name of the publish rule
    """
    return capsule_get_rule_name(capsule, "publish")

def capsule_get_workspace_path(capsule):
    """
    Gets the workspace path to the capsule.

    Args:
        capsule: return value of capsule_declare()
    Returns:
        str: the workspace path to the capsule
    """
    return _get_option(capsule, _OPTION_SOURCE_DIRECTORY)

def capsule_get_checkout_type(capsule, run_name):
    """
    This will either download pre-built binaries matching the capsule or checkout the source to build the capsule.

    Args:
        capsule: return value of capsule_declare()
        run_name: the name of the optional run target to activate if pre-built binaries are not available

    Returns:
        CHECKOUT_TYPE_OPTIONAL if the binary was downloaded
    """

    ORAL_URL = _get_option(capsule, _OPTION_ORAS_URL)
    GH_DEPLOY_REPO = _get_option(capsule, _OPTION_GH_DEPLOY_REPO)
    IS_USE_SOURCE = _get_option(capsule, _OPTION_IS_USE_SOURCE)
    CAPSULE_NAME = _to_name(capsule)
    CAPSULES_KEY = "capsules"
    NOTES_KEY = "notes"
    DESCRIPTION_KEY = "description"

    is_activate_checkout = None

    if IS_USE_SOURCE == True:
        is_activate_checkout = True
    elif fs_exists(_STATUS_JSON):
        STATUS = fs_read_json(_STATUS_JSON)
        CAPSULE_STATUS = STATUS[CAPSULES_KEY][CAPSULE_NAME]
        is_activate_checkout = CAPSULE_STATUS == _STATUS_SOURCE

    if is_activate_checkout == None:
        if ORAL_URL != None or GH_DEPLOY_REPO != None:
            is_activate_checkout = _add_archive(capsule) == None
        else:
            is_activate_checkout = True
        
    checkout_update_asset(
        capsule_get_rule_name(capsule, "checkout_status"),
        destination = _STATUS_JSON,
        value = {
            NOTES_KEY: "Change from `{}` to `{}` and run `spaces sync` to download and build from source".format(_STATUS_DOWNLOADED, _STATUS_SOURCE),
            DESCRIPTION_KEY: "This is generated by `@star/sdk/star/capsule.star` it tracks the status of binary downloaded vs build from source capsules",
            CAPSULES_KEY: {
                _to_name(capsule): _STATUS_DOWNLOADED if not is_activate_checkout else _STATUS_SOURCE
            }
        }
    )

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
    CHECKOUT_RULE_TYPE = capsule_get_checkout_type(capsule, run_name)
    checkout_add_repo(
        capsule_get_workspace_path(capsule),
        url = GIT_URL,
        type = CHECKOUT_RULE_TYPE,
        rev = _get_option(capsule, _OPTION_REV),
        clone = clone,
    )
    return CHECKOUT_RULE_TYPE

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
        capsule: return value of capsule_declare()
        deps: The dependencies of the capsule
    """

    RELOCATE_RULE_NAME = capsule_get_rule_name(capsule, "relocate")
    WORKSPACE = workspace_get_absolute_path()
    rpath_update_macos_install_dir(
        RELOCATE_RULE_NAME,
        install_path = "{}/{}".format(WORKSPACE, _get_option(capsule, _OPTION_INSTALL_PATH)),
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
        capsule: return value of capsule_declare()
        run_name: The run rule that will build and install (not publish) the target
    """

    NAME = _to_name(capsule)
    run_add_target(
        "{}_run".format(NAME),
        deps = [run_name],
    )

def capsule_get_deps(capsule):
    """
    Get the dependencies of the capsule.

    The deps must all be declared in the same spaces file.

    Args:
        capsule: return value of capsule_declare()

    Returns:
        list: The dependencies of the capsule
    """

    DEPS = _get_option(capsule, _OPTION_CAPSULE_DEPS)
    return [
        capsule_get_run_name(dep)
        for dep in DEPS
    ]

def capsule_get_prefix_paths(capsule):
    """
    Get the prefix paths of the capsule dependencies.

    Args:
        capsule: return value of capsule_declare()

    Returns:
        list: The prefix paths of the capsule dependencies. This can be used by cmake targets to find the dependencies.
    """

    DEPS = _get_option(capsule, _OPTION_CAPSULE_DEPS)
    return [
        capsule_get_install_path(dep)
        for dep in DEPS
    ]
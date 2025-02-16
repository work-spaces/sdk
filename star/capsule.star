"""
Spaces starlark functions for creating and working with capsules
"""

load(
    "checkout.star",
    "CHECKOUT_TYPE_OPTIONAL",
    "checkout_add_oras_archive",
    "checkout_add_platform_archive",
)
load(
    "internal/capsule.star",
    "internal_capsule_create_descriptor",
    "internal_capsule_create_options",
)
load("run.star", "run_add_target")

def capsule_declare(
        domain,
        owner,
        repo,
        version,
        source_revision = None,
        archive_suffix = "tar.xz",
        install_path = None,
        oras_deploy_repo = None,
        gh_deploy_repo = None,
        is_use_source = False):
    DESCRIPTOR = internal_capsule_create_descriptor(domain, owner, repo)
    OPTIONS = internal_capsule_create_options(
        version,
        source_revision,
        archive_suffix = archive_suffix,
        install_path = install_path,
        oras_deploy_repo = oras_deploy_repo,
        gh_deploy_repo = gh_deploy_repo,
        is_use_source = is_use_source,
    )
    return internal_capsule_create(DESCRIPTOR, OPTIONS)

def _add_checkout_oras(capsule):
    """
    Add the oras capsule to the sysroot.

    If the release is not available None is returned. Otherwise, a platform archive dictionary is returned.

    Args:
        capsule: return value of capsule()

    Returns:
        dict: with the platform and the url to download the gh executable
    """

    digest = info.get_workspace_short_digest()
    ORAS_COMMAND = "{}/sysroot/bin/oras".format(info.get_path_to_spaces_tools())
    ORAS_LABEL = internal_capsule_to_oras_label(capsule)

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

    PUBLISH_NAME = internal_capsule_to_rule_name(capsule, "publish")
    checkout_add_oras_archive(
        PUBLISH_NAME,
        url = url,
        artifact = _descriptor_to_oras_artifact(capsule),
        tag = "{}-{}".format(version, digest),
        add_prefix = _get_store_prefix(capsule),
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
    capsule_name = _descriptor_to_name(capsule)
    release_name = "{}-v{}".format(capsule_name, digest)
    gh_command = "{}/sysroot/bin/gh".format(info.get_path_to_spaces_tools())

    # Check gh to see if the executable is available
    check_release = process.exec({
        "command": gh_command,
        "args": [
            "release",
            "view",
            release_name,
            "--repo={}".format(deploy_repo),
            "--json=assets",
        ],
    })

    if check_release["status"] != 0:
        # the release is not available
        return None

    # check to see if the release is available for the platform
    platform = info.get_platform_name()
    url = "{}/releases/download/{}/{}-{}".format(deploy_repo, release_name, release_name, platform)

    platform_url = "{}.{}".format(url, suffix)
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

    PUBLISH_NAME = internal_capsule_to_rule_name(capsule, "publish")
    checkout_add_platform_archive(
        PUBLISH_NAME,
        platforms = {
            platform: {
                "url": platform_url,
                "sha256": platform_sha256_url,
                "link": "Hard",
                "add_prefix": _get_store_prefix(capsule_name),
            },
        },
    )

    return PUBLISH_NAME

def _add_archive(capsule):
    ORAS_URL = internal_capsule_get_option(capsule, INTERNAL_CAPSULE_OPTION_ORAS_URL)
    GH_DEPLOY_REPO = internal_capsule_get_option(capsule, INTERNAL_CAPSULE_OPTION_GH_DEPLOY_REPO)
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
    return internal_capsule_to_rule_name(capsule, "run")

def capsule_get_publish_name(capsule):
    """
    Gets the name of the run rule associated with this capsule.

    Dependents should depend on this rule to build the capsule.

    Args:
        capsule: return value of capsule()
    Returns:
        str: the name of the run rule
    """
    return internal_capsule_to_rule_name(capsule, "publish")

def capsule_get_workspace_path(capsule):
    """
    Gets the name of the run rule associated with this capsule.

    Dependents should depend on this rule to build the capsule.

    Args:
        capsule: return value of capsule()
    Returns:
        str: the name of the run rule
    """
    return internal_capsule_to_worspace_path(capsule)

def capsule_get_checkout_type(capsule, run_name):
    """
    This will either download pre-built binaries matching the capsule or checkout the source to build the capsule.

    Args:
        capsule: return value of capsule()
        run_name: the name of the optional run target to activate if pre-built binaries are not available

    Returns:
        The name of the run target that dependents should use to build from source or use the pre-built binaries
    """

    ORAL_URL = internal_capsule_get_option(capsule, INTERNAL_CAPSULE_OPTION_ORAS_URL)
    GH_DEPLOY_REPO = internal_capsule_get_option(capsule, INTERNAL_CAPSULE_OPTION_GH_DEPLOY_REPO)
    IS_USE_SOURCE = internal_capsule_get_option(capsule, INTERNAL_CAPSULE_OPTION_IS_USE_SOURCE)

    is_activate_checkout = False
    platform_archive_rule = None
    if not IS_USE_SOURCE and (ORAL_URL != None or GH_DEPLOY_REPO != None):
        platform_archive_rule = _add_archive(capsule)

    # no platform archive ready -- need to checkout the source repo
    if platform_archive_rule == None:
        is_activate_checkout = True

    run_add_target(
        capsule_checktou_get_run_name(capsule),
        deps = [run_name] if is_activate_checkout else [],
    )

    return None if is_activate_checkout else CHECKOUT_TYPE_OPTIONAL

def capsule_checkout_add_repo(
    capsule,
    run_name,
    clone = "Blobless",
    ):
    GIT_URL = internal_capsule_to_url(capsule)
    checkout_add_repo(
        capsule_get_path(capsule),
        url = GIT_URL,
        type = capsule_get_checkout_type(capsule, run_name),
        rev = internal_capsule_get_option(capsule, INTERNAL_CAPSULE_OPTION_SOURCE_REVISION),
        clone = clone,
    )


def _oras_publish(
        capsule,
        deps):
    oras_add_publish_archive(
        capsule_get_publish_name(capsule),
        url = internal_capsule_get_option(capsule, INTERNAL_CAPSULE_OPTION_ORAS_URL),
        deploy_repo = internal_capsule_get_option(capsule, INTERNAL_CAPSULE_OPTION_GH_DEPLOY_REPO),
        artifact = internal_capsule_to_oras_artifact(capsule),
        tag = internal_capsule_get_option(capsule, INTERNAL_CAPSULE_OPTION_RELEASE_VERSION),
        input = internal_capsule_get_option(capsule, INTERNAL_CAPSULE_OPTION_INSTALL_PATH),
        deps = deps,
        suffix = internal_capsule_get_option(capsule, INTERNAL_CAPSULE_OPTION_ARCHIVE_SUFFIX),
    )

def _gh_publish(
        capsule,
        deps):
    gh_add_publish_archive(
        capsule_get_publish_name(capsule),
        input = internal_capsule_get_option(capsule, INTERNAL_CAPSULE_OPTION_INSTALL_PATH),
        version = internal_capsule_get_option(capsule, INTERNAL_CAPSULE_OPTION_RELEASE_VERSION),
        deploy_repo = internal_capsule_get_option(capsule, INTERNAL_CAPSULE_OPTION_GH_DEPLOY_REPO),
        suffix = internal_capsule_get_option(capsule, INTERNAL_CAPSULE_OPTION_ARCHIVE_SUFFIX),
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

    RELOCATE_RULE_NAME = internal_capsule_to_rule_name(capsule, "relocate")
    rpath_update_macos_install_dir(
        RELOCATE_RULE_NAME,
        install_path = install_path,
        deps = deps,
    )

    if internal_capsule_get_option(capsule, INTERNAL_CAPSULE_OPTION_ORAS_URL) != None:
        _oras_publish(
            capsule,
            deps = [RELOCATE_RULE_NAME],
        )
    elif internal_capsule_get_option(capsule, INTERNAL_CAPSULE_OPTION_GH_DEPLOY_REPO) != None:
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

    NAME = internal_capsule_to_name(capsule)
    run_add_target(
        "{}_run".format(NAME),
        deps = [run_name],
    )

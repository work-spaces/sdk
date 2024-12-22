"""
Spaces starlark functions for creating and working with capsules
"""

load(
    "checkout.star",
    "checkout_add_capsule",
    "checkout_add_oras_archive",
    "checkout_add_platform_archive",
    "checkout_add_repo",
    "checkout_add_soft_link_asset",
    "checkout_update_asset",
)
load(
    "oras.star",
    "oras_add_publish_archive",
)
load("gh.star", "gh_add_publish_archive")
load("rpath.star", "rpath_update_macos_install_dir")

def capsule(
        domain,
        owner,
        repo):
    """
    Create a capsule descriptor. This is used with checkout_add_capsule().

    Args:
        domain (str): The domain of the repository
        owner (str): The owner of the repository
        repo (str): The repository name
    """

    return {
        "domain": domain,
        "owner": owner,
        "repo": repo,
    }

def capsule_github(
        owner,
        repo):
    """
    Create a capsule descriptor for github. This is used with checkout_add_capsule().

    Args:
        owner (str): The owner of the repository
        repo (str): The repository name
    """

    return capsule("github.com", owner, repo)

def _descriptor_to_name(descriptor):
    """
    Convert a capsule descriptor to a name.

    Args:
        descriptor: The capsule descriptor

    Returns:
        str: The name of the capsule
    """

    dev_mark = "" if info.is_workspace_reproducible() else "-non-reproducible"
    return "{}-{}-{}{}".format(
        descriptor["domain"],
        descriptor["owner"],
        descriptor["repo"],
        dev_mark,
    )

def _descriptor_to_oras_artifact(capsule):
    """
    Convert a capsule descriptor to an oras artifact.

    Args:
        capsule: The capsule descriptor

    Returns:
        str: The oras artifact (excludes the digest)
    """

    capsule_name = _descriptor_to_name(capsule)
    return "{}-{}".format(capsule_name, info.get_platform_name())

def _descriptor_to_oras_label(url, capsule):
    """
    Convert a capsule descriptor to an oras label.

    Args:
        url: The URL of the oras archive
        capsule: The capsule descriptor

    Returns:
        str: The oras label
    """

    oras_artifact = _descriptor_to_oras_artifact(capsule)
    return "{}/{}".format(url, oras_artifact)

def _get_store_prefix(capsule):
    """
    Get the prefix of the capsule.

    This is where the capsule is available on the machine. This is used
    when creating capsules.

    Args:
        capsule: return value of capsule()

    Returns:
        The prefix of the capsule
    """
    store = info.get_path_to_store()
    digest = info.get_workspace_digest()
    capsule_name = _descriptor_to_name(capsule)
    return "{}/capsules/{}/{}".format(store, capsule_name, digest)

def _get_install_path(capsule):
    """
    Check if the capsule is required to be checked out and run.

    This is used when writing workflows that create capsules. If the return value
    is None, the capsure is already available on the machine.

    Args:
        capsule: return value of capsule()

    Returns:
        None if the capsule is already available, otherwise the path to install the capsule
    """

    digest = info.get_workspace_digest()
    install_path = _get_store_prefix(capsule)
    capsule_info_path = "{}/{}.json".format(install_path, digest)
    if fs.exists(capsule_info_path):
        return None
    return install_path

def _oras_publish(
        name,
        capsule,
        deps,
        url,
        deploy_repo,
        suffix = "tar.xz"):
    """
    Publish the capsule to github

    Args:
        name: The name of the rule
        capsule: capsule()
        deps: The dependencies of the capsule
        url: Oras URL to publish the capsule
        deploy_repo: The repository to associate the capsule with
        suffix: The suffix of the archive file (tar.gz, tar.xz, tar.bz2, zip)
    """

    digest = info.get_workspace_digest()
    install_path = _get_store_prefix(capsule)

    oras_add_publish_archive(
        name,
        url = url,
        deploy_repo = deploy_repo,
        artifact = _descriptor_to_oras_artifact(capsule),
        tag = digest,
        input = install_path,
        deps = deps,
        suffix = suffix,
    )

def capsule_checkout(
        name,
        scripts,
        prefix,
        deps = []):
    """
    Checks out a capsule and adds it to the workspace.

    Args:
        name (str): The name of the rule.
        scripts (list): List of scripts to run that define how to install the capsule on the local machine.
        prefix (str): The workspace prefix where capsule artifacts should be hard-linked. Use `sysroot` for build deps and `build/install` for runtime deps.
        deps (list): List of dependencies for creating the capsule.
    """
    checkout_add_capsule(name, scripts, prefix = prefix, deps = deps)

def _oras_add(name, capsule, url):
    """
    Add the oras capsule to the sysroot.

    If the release is not available None is returned. Otherwise, a platform archive dictionary is returned.

    Args:
        name: rule name for checking out the capsule
        capsule: return value of capsule()
        url: The URL

    Returns:
        dict: with the platform and the url to download the gh executable
    """

    digest = info.get_workspace_digest()
    oras_command = "{}/sysroot/bin/oras".format(info.get_path_to_spaces_tools())
    oras_label = "{}:{}".format(_descriptor_to_oras_label(url, capsule), digest)

    # Check oras to see if the executable is available
    check_release = process.exec({
        "command": oras_command,
        "args": [
            "manifest",
            "fetch",
            oras_label,
        ],
    })

    if check_release["status"] != 0:
        # the release is not available
        return None

    if not json.is_string_json(check_release["stdout"]):
        # manifest fetch doesn't return an error on failure
        # but is doesn't return a json string
        return None

    checkout_platform_rule = "{}_add_platform_archive".format(name)
    checkout_add_oras_archive(
        checkout_platform_rule,
        url = url,
        artifact = _descriptor_to_oras_artifact(capsule),
        tag = digest,
        add_prefix = _get_store_prefix(capsule),
    )

    return checkout_platform_rule

def _gh_publish(name, capsule, deps, deploy_repo, suffix = "tar.xz"):
    """
    Publish the capsule to github

    Args:
        name: The name of the rule
        capsule: return value of capsule()
        deps: The dependencies of the capsule
        deploy_repo: The repository to deploy the capsule to
        suffix: The suffix of the archive file (tar.gz, tar.xz, tar.bz2, zip)
    """

    digest = info.get_workspace_digest()
    install_path = _get_store_prefix(capsule)
    capsule_name = _descriptor_to_name(capsule)

    gh_add_publish_archive(
        capsule_name,
        input = install_path,
        version = digest,
        deploy_repo = deploy_repo,
        deps = deps,
        suffix = suffix,
    )

def _gh_add(name, capsule, deploy_repo, suffix = "tar.xz"):
    """
    Add the gh executable to the sysroot.

    If the release is not available None is returned. Otherwise, a platform archive dictionary is returned.

    Args:
        name: same name used with _gh_publish()
        capsule: return value of capsule()
        deploy_repo: The repository to deploy the capsule to
        suffix: The suffix of the archive file (tar.gz, tar.xz, tar.bz2, zip)

    Returns:
        str: the name of checkout rule for the platform archive
    """

    # https://github.com/work-spaces/tools/releases/download/ninja-v1.12.1/ninja-v1.12.1-macos-x86_64.sha256.txt
    digest = info.get_workspace_digest()
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

    checkout_platform_rule = "{}_add_platform_archive".format(capsule_name)
    checkout_add_platform_archive(
        checkout_platform_rule,
        platforms = {
            platform: {
                "url": platform_url,
                "sha256": platform_sha256_url,
                "link": "Hard",
                "add_prefix": _get_store_prefix(capsule_name),
            },
        },
    )

    return checkout_platform_rule

def capsule_checkout_add_workflow_repo(
        name,
        url,
        rev,
        clone = "Worktree"):
    """
    Adds a repository to the @capsules folder where `spaces checkout` is called.

    The files in the repo will be available to _add_archive() scripts argument. The
    files will not be evaluated in the parent workspace.

    Args:
        name: The name of the rule
        url: The url of the repository
        rev: The revision of the repository
        clone: Default is Worktree

    Returns:
        str: Name of the checkout rule
    """

    checkout_rule_name = "{}/{}".format(info.get_path_to_capsule_workspace(), name)

    checkout_add_repo(
        checkout_rule_name,
        url = url,
        rev = rev,
        clone = clone,
        is_evaluate_spaces_modules = False,
    )

    return checkout_rule_name

def capsule_checkout_add_workflow_repo_as_soft_link(name):
    """
    Soft link the parent workflow repo to the capsule.

    Args:
        name: The name of the rule

    Returns:
        str: Name of the checkout rule to add the soft link
    """

    rule_name = "{}_soft_link_parent".format(name)
    workspace = info.get_absolute_path_to_workspace()
    source = "{}/../{}".format(workspace, name)

    checkout_add_soft_link_asset(
        rule_name,
        destination = "@capsules/{}".format(name),
        source = source,
    )

    return rule_name

def _checkout_define_dependency(
        name,
        capsule,
        version):
    """
    Define a capsule dependency.

    This used when creating capsules. It is used to tell the capsule consumer
    information about what dependencies are available when this workflow is
    added as a capsule dependency.

    Args:
        name: The name of the rule
        capsule: return value of capsule()
        version: The version of the dependency
    """

    capsule_prefix = _get_store_prefix(capsule)

    checkout_update_asset(
        name,
        destination = "capsules.spaces.json",
        value = [{
            "descriptor": capsule,
            "version": version,
            "prefix": capsule_prefix,
        }],
    )

def _add_archive(
        name,
        capsule,
        oras_url = None,
        gh_deploy_repo = None,
        suffix = "tar.xz"):
    """
    Add the the executable to the sysroot.

    If the release is not available None is returned. Otherwise, a platform archive dictionary is returned.

    Args:
        name: same name used with _gh_publish()
        capsule: return value of capsule()
        oras_url: The oras URL to deploy the capsule to
        gh_deploy_repo: The repository to deploy the capsule to
        suffix: The suffix of the archive file (tar.gz, tar.xz, tar.bz2, zip)

    Returns:
        str: the name of checkout rule for the platform archive
    """

    if oras_url != None:
        return _oras_add(
            name,
            capsule = capsule,
            url = oras_url,
        )
    elif gh_deploy_repo != None:
        return _gh_add(
            name,
            capsule = capsule,
            deploy_repo = gh_deploy_repo,
            suffix = suffix,
        )

    return None

def capsule_relocate_and_publish(
        name,
        capsule,
        deps,
        install_path,
        oras_url = None,
        gh_deploy_repo = None,
        suffix = "tar.xz"):
    """
    Relocate the capsule and publish to github.

    Args:
        name: The name of the rule
        capsule: return value of capsule()
        deps: The dependencies of the capsule
        oras_url: oras URL for publishing the capsule
        gh_deploy_repo: The repository to deploy the capsule to
        install_path: The path to install the capsule
        suffix: The suffix of the archive file (tar.gz, tar.xz, tar.bz2, zip)
    """

    capsule_name = _descriptor_to_name(capsule)

    relocate_rule_name = "{}_update_macos_install_dir".format(capsule_name)
    rpath_update_macos_install_dir(
        relocate_rule_name,
        install_path = install_path,
        deps = deps,
    )

    if oras_url != None:
        _oras_publish(
            name,
            capsule = capsule,
            deps = [relocate_rule_name],
            url = oras_url,
            deploy_repo = gh_deploy_repo,
            suffix = suffix,
        )
    elif gh_deploy_repo != None:
        _gh_publish(
            name,
            capsule_name = capsule_name,
            deps = [relocate_rule_name],
            deploy_repo = gh_deploy_repo,
            suffix = suffix,
        )
    else:
        checkout.abort("Must specify either `oras_url` or `gh_deploy_repo`")

def capsule_add_checkout_and_run(
        name,
        capsule,
        version,
        build_function,
        build_function_args,
        oras_url = None,
        gh_deploy_repo = None,
        suffix = "tar.gz"):
    """
    Add the checkout and run if the install path does not exist

    Args:
        name: The name of the rule
        capsule: return value of capsule()
        version: The version of the repository
        oras_url: The oral URL to deploy the capsule to
        gh_deploy_repo: The gh repository to deploy the capsule to
        suffix: The suffix of the archive file (tar.gz, tar.xz, tar.bz2, zip)
        build_function: The function to build the capsule
        build_function_args: dict to pass to the build function
    """

    capsule_name = _descriptor_to_name(capsule)

    _checkout_define_dependency(
        "{}_info".format(capsule_name),
        capsule = capsule,
        version = version,
    )

    install_path = _get_install_path(capsule)
    if install_path != None:
        capsule_publish_name = "{}_capsule".format(capsule_name)

        platform_archive_rule = None
        if oras_url != None or gh_deploy_repo != None:
            platform_archive_rule = _add_archive(
                capsule_publish_name,
                capsule = capsule,
                oras_url = oras_url,
                gh_deploy_repo = gh_deploy_repo,
                suffix = suffix,
            )

        if platform_archive_rule == None:
            # build from source and install
            capsule_from_source = "{}_source".format(capsule_name)

            build_function(capsule_from_source, install_path, build_function_args)

            if oras_url != None or gh_deploy_repo != None:
                capsule_relocate_and_publish(
                    capsule_publish_name,
                    capsule = capsule,
                    deps = [capsule_from_source],
                    oras_url = oras_url,
                    gh_deploy_repo = gh_deploy_repo,
                    install_path = install_path,
                    suffix = suffix,
                )

    # If neither oras_url or gh_deploy_repo is specified, the capsule is not published

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

def capsule_descriptor_to_name(descriptor):
    """
    Convert a capsule descriptor to a name.

    Args:
        descriptor: The capsule descriptor

    Returns:
        str: The name of the capsule
    """

    return "{}-{}-{}".format(
        descriptor["domain"],
        descriptor["owner"],
        descriptor["repo"],
    )

def capsule_descriptor_to_oras_artifact(capsule):
    """
    Convert a capsule descriptor to an oras artifact.

    Args:
        capsule: The capsule descriptor

    Returns:
        str: The oras artifact (excludes the digest)
    """

    capsule_name = capsule_descriptor_to_name(capsule)
    return "{}-{}".format(capsule_name, info.get_platform_name())

def capsule_descriptor_to_oras_label(url, capsule):
    """
    Convert a capsule descriptor to an oras label.

    Args:
        url: The URL of the oras archive
        capsule: The capsule descriptor

    Returns:
        str: The oras label
    """

    oras_artifact = capsule_descriptor_to_oras_artifact(capsule)
    return "{}/{}".format(url, oras_artifact)

def capsule_dependency(
        domain,
        owner,
        repo,
        semver,
        dependency_type = "Build"):
    """
    Create a capsule dependency descriptor. This used with checkout_add_capsule().

    Args:
        domain (str): The domain of the dependency
        owner (str): The owner of the dependency
        repo (str): The repo of the dependency
        semver (str): The semver of the dependency
        dependency_type (str): The type of dependency (Build is the default)

    Returns:
        dict: The capsule dependency descriptor
    """

    return {
        "descriptor": capsule(domain, owner, repo),
        "semver": semver,
        "dependency_type": dependency_type,
    }

def capsule_get_store_prefix(capsule):
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
    capsule_name = capsule_descriptor_to_name(capsule)
    return "{}/capsules/{}/{}".format(store, capsule_name, digest)

def capsule_get_depedency_info(depedency):
    """
    Gets the information about the dependency.

    The depedency is resolved from all the capsules available using sematic versioning. The
    minimal version solutions algorithm is used.

    Args:
        depedency: The dependency descriptor

    Returns:
        dict: with relevant information about the dependency
    """
    return info.get_capsule_info(depedency)

def capsule_get_install_path(capsule):
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
    install_path = capsule_get_store_prefix(capsule)
    capsule_info_path = "{}/{}.json".format(install_path, digest)
    if fs.exists(capsule_info_path):
        return None
    return install_path

def capsule_oras_publish(name, capsule, deps, url, suffix = "tar.xz"):
    """
    Publish the capsule to github

    Args:
        name: The name of the rule
        capsule: capsule()
        deps: The dependencies of the capsule
        url: Oras URL to publish the capsule
        suffix: The suffix of the archive file (tar.gz, tar.xz, tar.bz2, zip)
    """

    digest = info.get_workspace_digest()
    install_path = capsule_get_store_prefix(capsule)

    oras_add_publish_archive(
        name,
        url = url,
        artifact = capsule_descriptor_to_oras_artifact(capsule),
        tag = digest,
        input = install_path,
        deps = deps,
        suffix = suffix,
    )

def capsule_checkout(
        name,
        required,
        scripts,
        prefix = None,
        deps = []):
    """
    Adds a capsule to the workspace.

    Args:
        name (str): The name of the rule.
        required (list): List of dependencies that the capsule is expected to provide. The items are the return value of capsule_dependency().
        scripts (list): List of scripts to run that define how to install the capsule on the local machine.
        prefix (str): The workspace prefix where capsule artifacts should be hard-linked. Default is not hard-linking
        deps (list): List of dependencies for creating the capsule.
    """
    checkout_add_capsule(name, required, scripts, prefix = prefix, deps = deps)

def capsule_oras_add(name, capsule, url):
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
    oras_label = "{}:{}".format(capsule_descriptor_to_oras_label(url, capsule), digest)

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

    checkout_platform_rule = "{}_add_platform_archive".format(name)
    checkout_add_oras_archive(
        checkout_platform_rule,
        url = url,
        artifact = capsule_descriptor_to_oras_artifact(capsule),
        tag = digest,
        add_prefix = capsule_get_store_prefix(capsule_name),
    )

    return checkout_platform_rule

def capsule_gh_publish(name, capsule, deps, deploy_repo, suffix = "tar.xz"):
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
    install_path = capsule_get_store_prefix(capsule)
    capsule_name = capsule_descriptor_to_name(capsule)

    gh_add_publish_archive(
        capsule_name,
        input = install_path,
        version = digest,
        deploy_repo = deploy_repo,
        deps = deps,
        suffix = suffix,
    )


def capsule_gh_add(name, capsule, deploy_repo, suffix = "tar.xz"):
    """
    Add the gh executable to the sysroot.

    If the release is not available None is returned. Otherwise, a platform archive dictionary is returned.

    Args:
        name: same name used with capsule_gh_publish()
        capsule: return value of capsule()
        deploy_repo: The repository to deploy the capsule to
        suffix: The suffix of the archive file (tar.gz, tar.xz, tar.bz2, zip)

    Returns:
        str: the name of checkout rule for the platform archive
    """

    # https://github.com/work-spaces/tools/releases/download/ninja-v1.12.1/ninja-v1.12.1-macos-x86_64.sha256.txt
    digest = info.get_workspace_digest()
    capsule_name = capsule_descriptor_to_name(capsule)
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
                "add_prefix": capsule_get_store_prefix(capsule_name),
            },
        },
    )

    return checkout_platform_rule

def capsule_add_workflow_repo(
        name,
        url,
        rev,
        clone = "Worktree"):
    """
    Adds a repository to the @capsules folder where `spaces checkout` is called.

    The files in the repo will be available to capsule_add() scripts argument. The
    files will not be evaluated in the parent workspace.

    Args:
        name: The name of the rule
        url: The url of the repository
        rev: The revision of the repository
        clone: Default is Worktree

    Returns:
        str: Name of the checkout rule
    """

    checkout_rule_name = "@capsules/{}".format(name)

    checkout_add_repo(
        checkout_rule_name,
        url = url,
        rev = rev,
        clone = clone,
        is_evaluate_spaces_modules = False,
    )

    return checkout_rule_name

def capsule_add_workflow_repo_as_soft_link(name):
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



def capsule_checkout_define_dependency(
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

    capsule_prefix = capsule_get_store_prefix(capsule)

    checkout_update_asset(
        name,
        destination = "capsules.spaces.json",
        value = [{
            "descriptor": capsule,
            "version": version,
            "prefix": capsule_prefix,
        }],
    )

def capsule_add(
        name,
        capsule,
        oras_url = None,
        gh_deploy_repo = None,
        suffix = "tar.xz"):
    """
    Add the gh executable to the sysroot.

    If the release is not available None is returned. Otherwise, a platform archive dictionary is returned.

    Args:
        name: same name used with capsule_gh_publish()
        capsule: return value of capsule()
        oras_url: The oras URL to deploy the capsule to
        gh_deploy_repo: The repository to deploy the capsule to
        suffix: The suffix of the archive file (tar.gz, tar.xz, tar.bz2, zip)

    Returns:
        str: the name of checkout rule for the platform archive
    """

    if oras_url != None and gh_deploy_repo != None:
        checkout.abort("Cannot specify both oras_url and gh_deploy_repo")

    if oras_url != None:
        return capsule_oras_add(
            name,
            capsule = capsule,
            url = oras_url,
        )
    elif gh_deploy_repo != None:
        return capsule_gh_add(
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

    capsule_name = capsule_descriptor_to_name(capsule)

    relocate_rule_name = "{}_update_macos_install_dir".format(capsule_name)
    rpath_update_macos_install_dir(
        relocate_rule_name,
        install_path = install_path,
        deps = deps
    )

    if oras_url != None:
        capsule_oras_publish(
            name,
            capsule = capsule,
            deps = [relocate_rule_name],
            url = oras_url,
            suffix = suffix,
        )
    elif gh_deploy_repo != None:
        capsule_gh_publish(
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

    if oras_url != None and gh_deploy_repo != None:
        checkout.abort("Cannot specify both oras_url and gh_deploy_repo")

    capsule_name = capsule_descriptor_to_name(capsule)

    capsule_checkout_define_dependency(
        "{}_info".format(capsule_name),
        capsule = capsule,
        version = version,
    )

    install_path = capsule_get_install_path(capsule)
    if install_path != None:
        capsule_publish_name = "{}_capsule".format(capsule_name)

        platform_archive_rule = None
        if oras_url != None or gh_deploy_repo != None:
            platform_archive_rule = capsule_add(
                capsule_publish_name,
                capsule = capsule,
                oras_url = oras_url,
                gh_deploy_repo = gh_deploy_repo,
                suffix = suffix,
            )
            

        if platform_archive_rule == None:
            # build from source and install
            capsule_from_source = "{}_build".format(capsule_name)

            build_function(capsule_from_source, install_path, build_function_args)

            if url != None:
                capsule_relocate_and_publish(
                    capsule_publish_name,
                    capsule_name = capsule_name,
                    deps = [capsule_from_source],
                    oras_url = oras_url,
                    gh_deploy_repo = gh_deploy_repo,
                    install_path = install_path,
                    suffix = suffix,
                )

    # If neither oras_url or gh_deploy_repo is specified, the capsule is not published

"""
Spaces starlark functions for creating and working with capsules
"""

load("checkout.star", "checkout_add_capsule", "checkout_update_asset", "checkout_add_platform_archive")
load("gh.star", "gh_add_publish_archive")

def capsule_get_prefix(name):
    """
    Get the prefix of the capsule.

    This is where the capsule is available on the machine. This is used
    when creating capsules.

    Args:
        name: The name of the capsule

    Returns:
        The prefix of the capsule
    """
    store = info.get_path_to_store()
    digest = info.get_workspace_digest()
    return "{}/capsules/{}/{}".format(store, name, digest)

def capsule_gh_publish(capsule_name, deps, deploy_repo, suffix = "tar.xz"):
    """
    Publish the capsule to github

    Args:
        capsule_name: The name of the capsule
        deps: The dependencies of the capsule
        deploy_repo: The repository to deploy the capsule to
        suffix: The suffix of the archive file (tar.gz, tar.xz, tar.bz2, zip)
    """
    
    store = info.get_path_to_store()
    digest = info.get_workspace_digest()
    install_path = "{}/capsules/{}/{}".format(store, capsule_name, digest)

    gh_add_publish_archive(
        capsule_name,
        input = install_path,
        version = digest,
        deploy_repo = deploy_repo,
        deps = deps,
        suffix = suffix,
    )

def capsule_gh_add(capsule_name, deploy_repo, suffix = "tar.xz"):
    """
    Add the gh executable to the sysroot.

    If the release is not available None is returned. Otherwise, a platform archive dictionary is returned.

    Args:
        capsule_name: The name of the capsule
        deploy_repo: The repository to deploy the capsule to
        suffix: The suffix of the archive file (tar.gz, tar.xz, tar.bz2, zip)
    
    Returns:
        dict: with the platform and the url to download the gh executable
    """

    # https://github.com/work-spaces/tools/releases/download/ninja-v1.12.1/ninja-v1.12.1-macos-x86_64.sha256.txt
    digest = info.get_workspace_digest()
    release_name = "{}-v{}".format(capsule_name, digest)

    # Check gh to see if the executable is available
    check_release = process.exec({
        "command": "gh",
        "args": [
            "release",
            "view",
            release_name,
            "--repo={}".format(deploy_repo),
            "--json=assets"
        ],
    })

    if check_release["status"] != 0:
        # the release is not available
        return None

    # check to see if the release is available for the platform
    platform = info.get_platform_name()
    url = "{}/releases/downloads/{}/{}-{}-{}".format(deploy_repo, release_name, release_name, platform)

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

    checkout_platform_rule = "{}_capsule_gh_add".format(capsule_name)
    checkout_add_platform_archive(
        checkout_platform_rule,
        platforms = {
            platform: {
                "url": platform_url,
                "sha256": platform_sha256_url,
                "link": "Hard",
                "add_prefix": capsule_get_prefix(capsule_name),
            }
        }
    )
   
    return checkout_platform_rule

   

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
        "descriptor": {
            "domain": domain,
            "owner": owner,
            "repo": repo,
        },
        "semver": semver,
        "dependency_type": dependency_type,
    }

def capsule_add(
        name,
        required,
        scripts,
        prefix = None,
        deps = []):
    """
    Adds a capsule dependency to the workspace.

    Args:
        name (str): The name of the rule.
        required (list): List of dependencies that the capsule is expected to provide. The items are the return value of capsule_dependency().
        scripts (list): List of scripts to run that define how to install the capsule on the local machine.
        prefix (str): The workspace prefix where capsule artifacts should be hard-linked. Default is not hard-linking
        deps (list): List of dependencies for creating the capsule.
    """
    checkout_add_capsule(name, required, scripts, prefix = prefix, deps = deps)

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

def capsule_get_install_path(name):
    """
    Check if the capsule is required to be checked out and run.

    This is used when writing workflows that create capsules. If the return value
    is None, the capsure is already available on the machine.

    Args:
        name: The name of the capsule

    Returns:
        None if the capsule is already available, otherwise the path to install the capsule
    """
    store = info.get_path_to_store()
    digest = info.get_workspace_digest()
    install_path = "{}/capsules/{}/{}".format(store, name, digest)
    if fs.exists(install_path):
        return None
    return install_path

def capsule_checkout_define_dependency(
        name,
        capsule_name,
        domain,
        owner,
        repo,
        version):
    """
    Define a capsule dependency.

    This used when creating capsules. It is used to tell the capsule consumer
    information about what dependencies are available when this workflow is
    added as a capsule dependency.

    Args:
        name: The name of the rule
        capsule_name: The name of the capsule (this is arbitrary and helps to manually browse the spaces store)
        domain: The domain of the dependency
        owner: The owner of the dependency
        repo: The repo of the dependency
        version: The version of the dependency
    """

    capsule_prefix = capsule_get_prefix(capsule_name)

    checkout_update_asset(
        name,
        destination = "capsules.spaces.json",
        value = [{
            "descriptor": {
                "domain": domain,
                "owner": owner,
                "repo": repo,
            },
            "version": version,
            "prefix": capsule_prefix,
        }],
    )
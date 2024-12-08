"""
Spaces starlark functions for creating and working with capsules
"""

load("checkout.star", "checkout_add_capsule", "checkout_update_asset")


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
    checkout_add_capsule(name, required, scripts, deps)

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
    install_path = "{}/capules/{}/{}".format(store, name, digest)
    if fs.exists(install_path):
        return None
    return install_path

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
    return "{}/capules/{}/{}".format(store, name, digest)

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
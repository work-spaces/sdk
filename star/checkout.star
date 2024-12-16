"""
User friendly wrapper functions for the spaces checkout built-in functions.
"""

def checkout_add_repo(
        rule_name,
        url,
        rev,
        checkout_type = "Revision",
        clone = "Default",
        is_evaluate_spaces_modules = None):
    """
    Clones a repository and checks it out at a specific revision.

    Args:
        rule_name (str): The name of the rule.
        url (str): The git repository URL to clone
        rev (str): The branch or commit hash to checkout
        checkout_type (str): Revision | NewBranch
        clone (str): Default | Worktree
        is_evaluate_spaces_modules (bool): Whether to evaluate spaces.star files in the repo (default is True).
    """

    evaluate_spaces_modules = {"is_evaluate_spaces_modules": is_evaluate_spaces_modules} if is_evaluate_spaces_modules != None else {}

    checkout.add_repo(
        rule = {"name": rule_name},
        repo = {
            "url": url,
            "rev": rev,
            "checkout": checkout_type,
            "clone": clone,
        } | evaluate_spaces_modules,
    )

def checkout_add_archive(
        name,
        url,
        sha256,
        link = "Hard",
        includes = None,
        excludes = None,
        strip_prefix = None,
        add_prefix = "./",
        filename = None):
    """
    Adds an archive to the workspace.

    Args:
        name (str): The name of the rule.
        url (str): The URL of the archive to download.
        sha256 (str): The SHA256 checksum of the archive.
        link (str): Hard | None
        includes (list): List of globs to include.
        excludes (list): List of globs to exclude.
        strip_prefix (str): Prefix to strip from the archive.
        add_prefix (str): Prefix to add to the archive.
        filename (str): The filename if it isn't the last part of the URL
    """
    checkout.add_archive(
        rule = {"name": name},
        archive = {
            "url": url,
            "sha256": sha256,
            "link": link,
            "includes": includes,
            "excludes": excludes,
            "strip_prefix": strip_prefix,
            "add_prefix": add_prefix,
            "filename": filename,
        },
    )

def checkout_add_asset(
        name,
        content,
        destination):
    """
    Adds an asset to the workspace.

    Args:
        name (str): The name of the rule.
        content (str): The content of the asset.
        destination (str): The destination path for the asset.
    """
    checkout.add_asset(
        rule = {"name": name},
        asset = {
            "content": content,
            "destination": destination,
        },
    )

def checkout_update_asset(
        name,
        destination,
        value,
        format = None):
    """
    Updates an asset in the workspace.

    Args:
        name (str): The name of the rule.
        destination (str): The destination path for the asset.
        format (str): The format of the asset (json | toml | yaml). Default will get extension from destination.
        value (str): The value of the asset.
    """

    effective_format = format if format != None else destination.split(".")[-1]

    checkout.update_asset(
        rule = {"name": name},
        asset = {
            "destination": destination,
            "format": effective_format,
            "value": value,
        },
    )

def checkout_add_cargo_bin(
        name,
        crate,
        version,
        bins):
    """
    Adds a cargo binary to the workspace.

    Args:
        name (str): The name of the rule.
        crate (str): The name of the crate.
        version (str): The version of the crate.
        bins (list): List of binaries to add.
    """
    checkout.add_cargo_bin(
        rule = {"name": name},
        cargo_bin = {
            "crate": crate,
            "version": version,
            "bins": bins,
        },
    )

def checkout_add_hard_link_asset(
        name,
        source,
        destination):
    """
    Adds a hard link asset to the workspace.

    Args:
        name (str): The name of the rule.
        source (str): The source path of the asset.
        destination (str): The destination path for the asset.
    """
    checkout.add_hard_link_asset(
        rule = {"name": name},
        asset = {
            "source": source,
            "destination": destination,
        },
    )

def checkout_add_soft_link_asset(
        name,
        source,
        destination):
    """
    Adds a hard link asset to the workspace.

    Args:
        name (str): The name of the rule.
        source (str): The source path of the soft link.
        destination (str): The relative workspace path of the soft link destination.
    """
    checkout.add_soft_link_asset(
        rule = {"name": name},
        asset = {
            "source": source,
            "destination": destination,
        },
    )

def checkout_add_target(
        name,
        deps):
    """
    Adds a target to the workspace.

    Args:
        name (str): The name of the rule.
        deps (list): List of dependencies for the target.
    """
    checkout.add_target(
        rule = {"name": name, "deps": deps},
    )

def checkout_add_platform_archive(
        name,
        platforms):
    """
    Adds a platform archive to the checkout.

    Args:
        name (str): The name of the rule.
        platforms (list): List of platforms to add the archive to.
    """
    checkout.add_platform_archive(
        rule = {"name": name},
        platforms = platforms,
    )

def checkout_update_env(
        name,
        vars = {},
        paths = [],
        system_paths = None,
        inherited_vars = None):
    """
    Updates the environment with the given variables and paths.

    Args:
        name (str): The name of the rule.
        vars (dict): Dictionary of environment variables to set.
        paths (list): List of paths to add to the PATH.
        system_paths (str): The path to add to the system PATH.
        inherited_vars (list): List of environment variables to inherit from the calling environment.
    """

    effective_inherited_vars = {"inherited_vars": inherited_vars } if inherited_vars != None else {}

    checkout.update_env(
        rule = {"name": name},
        env = {
            "paths": paths,
            "vars": vars,
            "system_paths": system_paths,
        } | effective_inherited_vars,
    )

def checkout_add_which_asset(
        name,
        which,
        destination):
    """
    Adds an asset to the destintion based on the which command.

    Args:
        name (str): The name of the rule.
        which (str): The name of the asset to add.
        destination (str): The destination path for the asset.
    """

    checkout.add_which_asset(
        rule = {"name": name},
        asset = {
            "which": which,
            "destination": destination,
        },
    )

def checkout_add_capsule(
        name,
        scripts,
        prefix = None,
        deps = []):
    """
    Adds a capsule dependency to the workspace.

    Args:
        name (str): The name of the rule.
        scripts (list): List of scripts to run that define how to install the capsule on the local machine.
        prefix (str): The workspace prefix where capsule artifacts should be hard-linked. Default is not hard-linking
        deps (list): List of dependencies for creating the capsule.
    """

    prefix_option = {"prefix": prefix} if prefix != None else {}

    checkout.add_capsule(
        rule = {"name": name, "deps": deps},
        capsule = {
            "scripts": scripts,
        } | prefix_option,
    )

def update_platforms_prefix(
        platforms,
        add_prefix):
    """
    Updates the prefix of the platforms.

    Args:
        platforms (list): List of platforms to update.
        add_prefix (str): The prefix to set.

    Returns:
        An updated list of platforms.
    """

    updated_platforms = {}
    available_platforms = info.get_supported_platforms()
    for platform in available_platforms:
        if platforms.get(platform):
            updated_platforms[platform] = platforms[platform] | {"add_prefix": add_prefix}

    return updated_platforms


def checkout_add_oras_archive(
    name,
    url,
    artifact,
    tag,
    add_prefix,
    manifest_digest_path = "/layers/0/digest",
    manifest_artifact_path = "/layers/0/annotations/org.opencontainers.image.title",
    globs = None):
    """
    Adds an oras archive to the workspace.

    Args:
        name (str): The name of the rule.
        url (str): The URL of the oras archive to download.
        artifact (str): The artifact name of the oras archive.
        tag (str): The tag of the oras archive.
        add_prefix (str): The prefix to add to the archive.
        manifest_digest_path (str): The path to the manifest digest in the oras archive.
        manifest_artifact_path (str): The path to the manifest artifact in the oras archive.
        globs (list): List of globs to include/exclude.
    """

    checkout.add_oras_archive(
    rule = { "name": name },
    oras_archive = {
        "url": url,
        "artifact": artifact,
        "tag": tag,
        "manifest_digest_path": manifest_digest_path,
        "manifest_artifact_path": manifest_artifact_path,
        "add_prefix": add_prefix,
        "globs": globs,
    }
)
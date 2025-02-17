"""
User friendly wrapper functions for the spaces checkout built-in functions.
"""

CHECKOUT_TYPE_OPTIONAL = "Optional"
CHECKOUT_TYPE_DEFAULT = None

def checkout_add_repo(
        name,
        url,
        rev,
        checkout_type = "Revision",
        clone = "Default",
        is_evaluate_spaces_modules = None,
        sparse_mode = None,
        sparse_list = None,
        working_directory = None,
        platforms = None,
        type = None,
        deps = []):
    """
    Clones a repository and checks it out at a specific revision.

    Args:
        name (str): The name of the rule.
        url (str): The git repository URL to clone
        rev (str): The branch or commit hash to checkout
        checkout_type (str): Revision | NewBranch
        clone (str): Default | Worktree
        is_evaluate_spaces_modules (bool): Whether to evaluate spaces.star files in the repo (default is True).
        sparse_mode (str): Cone | NoCone
        sparse_list (list): List of paths to include/exclude
        deps (list): List of dependencies for the rule.
        type: CHECKOUT_TYPE_OPTIONAL to make the rule optional (must be trigger by another rule to execute).
        platforms (list): List of platforms to add the archive to.
        working_directory (str): The working directory to clone the repository into.
    """

    EVALUATE_SPACES_MODULES = {
        "is_evaluate_spaces_modules": is_evaluate_spaces_modules,
    } if is_evaluate_spaces_modules != None else {}
    EFFECTIVE_SPARSE_CHECKOUT = {
        "sparse_checkout": {"mode": sparse_mode, "list": sparse_list},
    } if sparse_mode != None else {}

    checkout.add_repo(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        },
        repo = {
            "url": url,
            "rev": rev,
            "checkout": checkout_type,
            "clone": clone,
            "working_directory": working_directory,
        } | EVALUATE_SPACES_MODULES | EFFECTIVE_SPARSE_CHECKOUT,
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
        filename = None,
        platforms = None,
        type = None,
        deps = []):
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
        platforms (list): List of platforms to add the archive to.
        type (str): CHECKOUT_TYPE_OPTIONAL to make the rule optional (must be trigger by another rule to execute).
        deps (list): List of dependencies for the rule.
    """
    checkout.add_archive(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        },
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
        destination,
        deps = [],
        type = None,
        platforms = None):
    """
    Adds an asset to the workspace.

    Args:
        name (str): The name of the rule.
        content (str): The content of the asset.
        destination (str): The destination path for the asset.
        deps (list): List of dependencies for the asset.
        type (str): CHECKOUT_TYPE_OPTIONAL to make the rule optional (must be trigger by another rule to execute).
        platforms (list): List of platforms to add the archive to.
    """
    checkout.add_asset(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        },
        asset = {
            "content": content,
            "destination": destination,
        },
    )

def checkout_update_asset(
        name,
        destination,
        value,
        format = None,
        deps = [],
        type = None,
        platforms = None):
    """
    Updates an asset in the workspace.

    Args:
        name (str): The name of the rule.
        destination (str): The destination path for the asset.
        format (str): The format of the asset (json | toml | yaml). Default will get extension from destination.
        value (str): The value of the asset.
        deps (list): List of dependencies for the asset.
        type (str): CHECKOUT_TYPE_OPTIONAL to make the rule optional (must be trigger by another rule to execute).
        platforms (list): List of platforms to add the archive to.
    """

    effective_format = format if format != None else destination.split(".")[-1]

    checkout.update_asset(
        rule = {
            "name": name, "deps": deps, "platforms": platforms, "type": type},
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
        bins,
        deps = [],
        type = None,
        platforms = None):
    """
    Adds a cargo binary to the workspace.

    Args:
        name (str): The name of the rule.
        crate (str): The name of the crate.
        version (str): The version of the crate.
        bins (list): List of binaries to add.
        deps (list): List of dependencies for the rule.
        type (str): CHECKOUT_TYPE_OPTIONAL to make the rule optional (must be trigger by another rule to execute).
        platforms (list): List of platforms to add the archive to.
    """
    checkout.add_cargo_bin(
        rule = {
            "name": name, "deps": deps, "platforms": platforms, "type": type},
        cargo_bin = {
            "crate": crate,
            "version": version,
            "bins": bins,
        },
    )

def checkout_add_hard_link_asset(
        name,
        source,
        destination,
        deps = [],
        type = None,
        platforms = None):
    """
    Adds a hard link asset to the workspace.

    Args:
        name (str): The name of the rule.
        source (str): The source path of the asset.
        destination (str): The destination path for the asset.
        deps (list): List of dependencies for the asset.
        type (str): CHECKOUT_TYPE_OPTIONAL to make the rule optional (must be trigger by another rule to execute).
        platforms (list): List of platforms to add the archive to.
    """
    checkout.add_hard_link_asset(
        rule = {
            "name": name, "deps": deps, "platforms": platforms, "type": type},
        asset = {
            "source": source,
            "destination": destination,
        },
    )

def checkout_add_soft_link_asset(
        name,
        source,
        destination,
        deps = [],
        type = None,
        platforms = None):
    """
    Adds a hard link asset to the workspace.

    Args:
        name (str): The name of the rule.
        source (str): The source path of the soft link.
        destination (str): The relative workspace path of the soft link destination.
        deps (list): List of dependencies for the asset.
        type (str): CHECKOUT_TYPE_OPTIONAL to make the rule optional (must be trigger by another rule to execute).
        platforms (list): List of platforms to add the archive to.
    """
    checkout.add_soft_link_asset(
        rule = {
            "name": name, "deps": deps, "platforms": platforms, "type": type},
        asset = {
            "source": source,
            "destination": destination,
        },
    )

def checkout_add_target(
        name,
        deps,
        type = None,
        platforms = None):
    """
    Adds a target to the workspace.

    Args:
        name (str): The name of the rule.
        deps (list): List of dependencies for the target.
        type (str): CHECKOUT_TYPE_OPTIONAL to make the rule optional (must be trigger by another rule to execute).
        platforms (list): List of platforms to build the target for (default is all).
    """
    checkout.add_target(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        },
    )

def checkout_add_platform_archive(
        name,
        platforms,
        deps = [],
        type = None):
    """
    Adds a platform archive to the checkout.

    Args:
        name (str): The name of the rule.
        platforms (list): List of platforms to add the archive to.
        deps (list): List of dependencies for the rule.
        type (str): CHECKOUT_TYPE_OPTIONAL to make the rule optional (must be trigger by another rule to execute).
    """
    checkout.add_platform_archive(
        rule = {"name": name, "type": type, "deps": deps},
        platforms = platforms,
    )

def checkout_update_env(
        name,
        vars = {},
        paths = [],
        system_paths = None,
        inherited_vars = None,
        deps = [],
        type = None,
        platforms = None):
    """
    Updates the environment with the given variables and paths.

    Args:
        name (str): The name of the rule.
        vars (dict): Dictionary of environment variables to set.
        paths (list): List of paths to add to the PATH.
        system_paths (str): The path to add to the system PATH.
        inherited_vars (list): List of environment variables to inherit from the calling environment.
        deps (list): List of dependencies for the rule.
        type (str): CHECKOUT_TYPE_OPTIONAL to make the rule optional (must be trigger by another rule to execute).
        platforms (list): List of platforms to add the archive to.
    """

    effective_inherited_vars = {"inherited_vars": inherited_vars} if inherited_vars != None else {}

    checkout.update_env(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        },
        env = {
            "paths": paths,
            "vars": vars,
            "system_paths": system_paths,
        } | effective_inherited_vars,
    )

def checkout_add_which_asset(
        name,
        which,
        destination,
        deps = [],
        platforms = None,
        type = None):
    """
    Adds an asset to the destintion based on the which command.

    Args:
        name (str): The name of the rule.
        which (str): The name of the asset to add.
        destination (str): The destination path for the asset.
        deps (list): List of dependencies for the asset.
        type (str): CHECKOUT_TYPE_OPTIONAL to make the rule optional (must be trigger by another rule to execute).
        platforms (list): List of platforms to add the archive to.
    """

    checkout.add_which_asset(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        },
        asset = {
            "which": which,
            "destination": destination,
        },
    )

def checkout_add_capsule(
        name,
        scripts,
        descriptor,
        prefix = None,
        globs = None,
        deps = [],
        platforms = None,
        type = None):
    """
    Adds a capsule dependency to the workspace.

    Args:
        name (str): The name of the rule.
        scripts (list): List of scripts to run that define how to install the capsule on the local machine.
        prefix (str): The workspace prefix where capsule artifacts should be hard-linked. Default is not hard-linking
        globs (list): List of globs to include/exclude.
        deps (list): List of dependencies for creating the capsule.
        descriptor (dict): domain, owner, repo
        type (str): CHECKOUT_TYPE_OPTIONAL to make the rule optional (must be trigger by another rule to execute).
        platforms (list): List of platforms to add the archive to.
    """

    checkout.add_capsule(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        },
        capsule = {
            "scripts": scripts,
            "prefix": prefix,
            "globs": globs,
            "descriptor": descriptor,
        },
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
        globs = None,
        deps = [],
        type = None,
        platforms = None):
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
        deps (list): List of dependencies for the rule.
        type (str): CHECKOUT_TYPE_OPTIONAL to make the rule optional (must be trigger by another rule to execute).
        platforms (list): List of platforms to add the archive to.
    """

    checkout.add_oras_archive(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        },
        oras_archive = {
            "url": url,
            "artifact": artifact,
            "tag": tag,
            "manifest_digest_path": manifest_digest_path,
            "manifest_artifact_path": manifest_artifact_path,
            "add_prefix": add_prefix,
            "globs": globs,
        },
    )

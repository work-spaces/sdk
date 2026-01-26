"""
User friendly wrapper functions for the spaces checkout built-in functions.
"""

load("info.star", "info_set_required_semver")

_CHECKOUT_SHELL_SPACES_TOML = "shell.spaces.toml"

# Clone rules that are optional are not run
CHECKOUT_TYPE_OPTIONAL = "Optional"

# Clone rules that are default are always run
CHECKOUT_TYPE_DEFAULT = None

# Sparse checkout modes
CHECKOUT_SPARSE_MODE_CONE = "Cone"  # checkout directories
CHECKOUT_SPARSE_MODE_NO_CONE = "NoCone"  #checkout gitignore like expressions

# Ways to `clone` a repository
CHECKOUT_CLONE_DEFAULT = "Default"  # Just a normal clone
CHECKOUT_CLONE_WORKTREE = "Worktree"  # stores the bare repository in the spaces store
CHECKOUT_CLONE_BLOBLESS = "Blobless"  # filters unused files from the repo history
CHECKOUT_CLONE_SHALLOW = "Shallow"  # The rev must be a branch not a tag or commit

# This is the only supported value
CHECKOUT_CLONE_TYPE_REVISION = "Revision"

def checkout_get_compile_commands_spaces_name():
    """
    Returns the name of the file used with checkout_add_compile_commands_dir().

    This is used internally between the checkout rule and compile_commands_merge()
    """
    return "compile_commands.spaces.json"

def checkout_type_optional():
    """
    Use `checkout_add_repo(type = checkout_type_optional())` to skip checkout

    Returns:
        str: CHECKOUT_TYPE_OPTIONAL
    """
    return CHECKOUT_TYPE_OPTIONAL

def checkout_type_default():
    """
    Use `checkout_add_repo(type = checkout_type_default())` to use default checkout behavior

    Returns:
        None: CHECKOUT_TYPE_DEFAULT
    """
    return CHECKOUT_TYPE_DEFAULT

def checkout_sparse_mode_cone():
    """
    Use `checkout_add_repo(sparse_mode = checkout_sparse_mode_cone())` for sparse cone mode.

    Returns:
        str: CHECKOUT_SPARSE_MODE_CONE
    """
    return CHECKOUT_SPARSE_MODE_CONE

def checkout_sparse_mode_no_cone():
    """
    Use `checkout_add_repo(sparse_mode = checkout_sparse_mode_no_cone())` for sparse no-cone mode.

    This mode uses gitignore-like expressions for sparse checkout.

    Returns:
        str: CHECKOUT_SPARSE_MODE_NO_CONE
    """
    return CHECKOUT_SPARSE_MODE_NO_CONE

def checkout_clone_default():
    """
    Use `checkout_add_repo(clone = checkout_clone_default())` for a normal git clone.

    Returns:
        str: CHECKOUT_CLONE_DEFAULT
    """
    return CHECKOUT_CLONE_DEFAULT

def checkout_clone_worktree():
    """
    Use `checkout_add_repo(clone = checkout_clone_worktree())` to store the bare repository in the spaces store.

    Returns:
        str: CHECKOUT_CLONE_WORKTREE
    """
    return CHECKOUT_CLONE_WORKTREE

def checkout_clone_blobless():
    """
    Use `checkout_add_repo(clone = checkout_clone_blobless())` to filter unused files from the repository history.

    Returns:
        str: CHECKOUT_CLONE_BLOBLESS
    """
    return CHECKOUT_CLONE_BLOBLESS

def checkout_clone_shallow():
    """
    Use `checkout_add_repo(clone = checkout_clone_shallow())` for a shallow clone.

    Note: The rev must be a branch, not a tag or commit.

    Returns:
        str: CHECKOUT_CLONE_SHALLOW
    """
    return CHECKOUT_CLONE_SHALLOW

def checkout_add_repo(
        name,
        url,
        rev,
        checkout_type = CHECKOUT_CLONE_TYPE_REVISION,
        clone = CHECKOUT_CLONE_BLOBLESS,
        is_evaluate_spaces_modules = None,
        sparse_mode = None,
        sparse_list = None,
        working_directory = None,
        platforms = None,
        type = None,
        deps = []):
    """
    Clones a repository and checks it out at a specific revision.

    The for `clone=checkout_clone_default() | checkout_clone_blobless()`, the repo
    is cloned first to the store and then copied to the workspace. If the filesystem
    supports copy-on-write (COW) semantics, COW semantics are used to copy from the
    store to the workspace.

    Example:

    ```python
    checkout_add_repo(
        "spaces",
        url = "https://github.com/work-spaces/spaces",
        rev = "main"
    )
    ```

    Args:
        name: `str` The name of the rule. This is also the location of the new repo in the workspace.
        url: `str` The git repository URL to clone
        rev: `str` The branch or commit hash to checkout
        checkout_type: `enum` Revision
        clone: `enum` [checkout_clone_default()](#checkout_clone_default) | [checkout_clone_blobless()](#checkout_clone_blobless) | [checkout_clone_worktree()](#checkout_clone_worktree)
        is_evaluate_spaces_modules: `bool` Whether to evaluate spaces.star files in the repo (default is True).
        sparse_mode: `enum` Cone | NoCone
        sparse_list: `[str]` List of paths to include/exclude
        deps: `[str]` List of dependencies for the rule.
        type: `str` use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        platforms: `[str]` List of platforms to add the repo to.
        working_directory: `str` The working directory to clone the repository into.
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
        headers = None,
        deps = []):
    """
    Adds an archive to the workspace.

    The archive is downloaded to the spaces store and hard-linked to the workspace.

    Args:
        name: `str` The name of the rule.
        url: `str` The URL of the archive to download.
        sha256: `str` The SHA256 checksum of the archive.
        link: `str` Hard | None
        includes: `[str]` List of globs to include.
        excludes: `[str]` List of globs to exclude.
        strip_prefix:`str` Prefix to strip from the archive.
        add_prefix: `str` Prefix to add to the archive.
        filename: `str` The filename if it isn't the last part of the URL
        platforms: `[str]` List of platforms to add the archive to.
        type: `str` use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        headers: `dict` key-value pairs of headers to use when downloading the archive.
        deps: `[str]` List of dependencies for the rule.
    """
    if headers != None:
        info_set_required_semver(">=0.15.2")

    effective_headers = {}
    if headers != None:
        effective_headers = {"headers": headers}

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
        } | effective_headers,
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

    This will create a file in the workspace with the given content as string value.

    Args:
        name: `str` The name of the rule.
        content: `str` The content of the file to create.
        destination: `str` The destination path for the file.
        deps: `[str]` List of dependencies for the rule.
        type: `str` use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        platforms: `[str]` List of [platforms](/docs/builtins/#rule-options) to add the archive to.
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

    This rule will merge the data of an existing JSON, TOML, or YAML file with the given value.

    Args:
        name: `str` The name of the rule.
        destination: `str` The destination path for the asset.
        format: `str` The format of the asset (json | toml | yaml). Default will get extension from destination.
        value: `dict|list` The value of the asset as a dict to merge with the existing file.
        deps: `[str]` List of dependencies for the asset.
        type: `str` use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        platforms: `[str]` List of [platforms](/docs/builtins/#rule-options) to add the archive to.
    """

    effective_format = format if format != None else destination.split(".")[-1]

    checkout.update_asset(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        },
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
        name: `str` The name of the rule.
        crate: `str` The name of the crate.
        version: `str` The version of the crate.
        bins: `[str]` List of binaries to add.
        deps: `[str]` List of dependencies for the rule.
        type: `str` use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        platforms: `[str]` List of [platforms](/docs/builtins/#rule-options) to add the archive to.
    """
    checkout.add_cargo_bin(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        },
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
        name: `str` The name of the rule.
        source: `str` The source path of the asset.
        destination: `str` The destination path for the asset.
        deps: `[str]` List of dependencies for the asset.
        type: `str` use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        platforms: `[str]` List of [platforms](/docs/builtins/#rule-options) to add the archive to.
    """
    checkout.add_hard_link_asset(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        },
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
    Adds a soft link asset to the workspace.

    Args:
        name: `str` The name of the rule.
        source: `str` The source path of the soft link.
        destination: `str` The relative workspace path of the soft link destination.
        deps: `[str]` List of dependencies for the asset.
        type: `str` use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        platforms: `[str]` List of [platforms](/docs/builtins/#rule-options) to add the archive to.
    """
    checkout.add_soft_link_asset(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        },
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
        name: `str` The name of the rule.
        deps: `[str]` List of dependencies for the target.
        type: `str` use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        platforms: `[str]` List of [platforms](/docs/builtins/#rule-options) to add the archive to.
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

    Platform archives are used to add binary tools based on the host platform.

    Args:
        name: `str` The name of the rule.
        platforms: `[str]` List of [platforms](/docs/builtins/#rule-options) to add the archive to.
        deps: `[str]` List of dependencies for the rule.
        type: `str` use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
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
        optional_inherited_vars = None,
        run_inherited_vars = None,
        secret_inherited_vars = None,
        deps = [],
        type = None,
        platforms = None):
    """
    Updates the environment with the given variables and paths.

    Variables other than PATH are added as key/value pairs. PATH is added as a list of values. The order
    of the PATHS is based on execution order which can be controlled using `deps`. The `system_paths`
    are added after the `paths` values.

    All vars are fixed at checkout time except vars specified in `run_inherited_vars`. Checkout vars
    are stored in the new workspace in `env.spaces.star`. `run_inherited_vars` are inherited when executing `spaces run`.
    `secret_inherited_vars` are inherited when executing spaces checkout or run. The values of the secrets are masked in the logs and terminal.

    Args:
        name: `str` The name of the rule.
        vars: `dict` Dictionary of variables to store in `env.spaces.star`.
        paths: `[str]` List of paths to add to the PATH.
        system_paths: `[str]` The path to add to the system PATH.
        inherited_vars: `[str]` List of variables to inherit from the calling environment and store in `env.spaces.star`.
        optional_inherited_vars: `[str]` List of variables to inherit from the calling environment if they exist and store in `env.spaces.star` (requires spaces >v0.15.1)
        run_inherited_vars: `[str]` List of variables inherited when executing spaces run.
        secret_inherited_vars: `[str]` List of variables inherited when executing spaces checkout/run. Values will be masked in the logs and terminal.
        deps: `[str]` List of dependencies for the rule.
        type: `str` use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        platforms: `[str]` List of [platforms](/docs/builtins/#rule-options) to add the archive to.
    """

    if optional_inherited_vars != None:
        info_set_required_semver(">=0.15.17")

    if run_inherited_vars != None:
        info_set_required_semver(">=0.15.17")

    if secret_inherited_vars != None:
        info_set_required_semver(">=0.15.21")

    effective_inherited_vars = {"inherited_vars": inherited_vars} if inherited_vars != None else {}
    effective_optional_inherited_vars = {"optional_inherited_vars": optional_inherited_vars} if optional_inherited_vars != None else {}
    effective_run_inherited_vars = {"run_inherited_vars": run_inherited_vars} if run_inherited_vars != None else {}
    secret_inherited_vars = {"secret_inherited_vars": secret_inherited_vars} if secret_inherited_vars != None else {}

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
              } |
              effective_inherited_vars |
              effective_optional_inherited_vars |
              effective_run_inherited_vars |
              secret_inherited_vars,
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

    Using this function creates system dependencies that may not be reproducible across different systems.

    Args:
        name: `str` The name of the rule.
        which: `str` The name of the asset to add.
        destination: `str` The destination path for the asset.
        deps: `[str]` List of dependencies for the asset.
        type: `str` use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        platforms: `[str]` List of [platforms](/docs/builtins/#rule-options) to add the archive to.
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

def update_platforms_prefix(
        platforms,
        add_prefix):
    """
    Updates the prefix of the platforms.

    Args:
        platforms: `[str]` List of [platforms](/docs/builtins/#rule-options) to add the archive to.
        add_prefix: The prefix to set.

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
        name: `str` The name of the rule.
        url: `str` The URL of the oras archive to download.
        artifact: `str` The artifact name of the oras archive.
        tag: `str` The tag of the oras archive.
        add_prefix: `str` The prefix to add to the archive.
        manifest_digest_path: `str` The path to the manifest digest in the oras archive.
        manifest_artifact_path: `str` The path to the manifest artifact in the oras archive.
        globs: `[str]` List of globs to include/exclude.
        deps: `[str]` List of dependencies for the rule.
        type: `str` use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        platforms: `[str]` List of [platforms](/docs/builtins/#rule-options) to add the archive to.
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

def checkout_add_compile_commands_dir(name, path, rule):
    """
    Registers a build directory in the compile_commands.spaces.json file.

    Args:
        name: `str` The name of the checkout rule.
        path: `str` The path to the build directory where compile_commands.json will be found.
        rule: `str` The name of the rule that is associated with creating the compile_command.json file.
    """

    checkout_update_asset(
        name,
        destination = checkout_get_compile_commands_spaces_name(),
        value = {"{}".format(path): "{}".format(rule)},
    )

def checkout_update_shell(name, shell_path, args = [], deps = []):
    """

    Updates the workspace shell configuration that is used with `spaces shell`

    Args:
        name: `str` The name of the rule.
        shell_path: `str` The path to the shell executable.
        args: `list` The arguments to pass to the shell.
        deps: `list` The dependencies of the rule (allows controlling order of updating the file)
    """
    checkout_update_asset(
        name,
        destination = _CHECKOUT_SHELL_SPACES_TOML,
        value = {
            "path": shell_path,
            "args": args,
        },
        deps = deps,
    )

def checkout_update_shell_startup(name, script_name, contents, env_name = None, deps = []):
    """

    Updates the workspace shell configuration that is used with `spaces shell`

    Args:
        name: `str` The name of the rule.
        script_name: `str` The name of the startup file to generate and store at `.spaces/shell/<script_name>` in the workspace.
        contents: `str` The contents of the startup file.
        env_name: `str` If not None, this will be set to point to the workspace shell startup directory `.spaces/shell`.
        deps: `list` The dependencies of the rule (allows controlling order of updating the file)
    """

    effective_env_name = {"env_name": env_name} if env_name else {}

    checkout_update_asset(
        name,
        destination = _CHECKOUT_SHELL_SPACES_TOML,
        value = {
            "startup": {
                "name": script_name,
                "contents": contents,
            } | effective_env_name,
        },
        deps = deps,
    )

def checkout_update_shell_shortcuts(name, shortcuts, deps = []):
    """

    Updates the `.spaces/shell/shortcuts.sh` file with shell functions. This file can be source when starting the shell.

    Args:
        name: `str` The name of the rule.
        shortcuts: `dict` A dictionary of function names (key) and shell commands to execute (values).
        deps: `list` A list of dependencies that allows override of shortcuts.
    """
    if shortcuts != None:
        checkout_update_asset(
            name,
            destination = _CHECKOUT_SHELL_SPACES_TOML,
            value = {
                "shortcuts": shortcuts,
            },
            deps = deps,
        )

def checkout_add_any_assets(
        name,
        assets,
        deps = [],
        type = None,
        platforms = None):
    """
    Adds a list of any assets to the workspace as a single rule.

    `assets` should be a list of dicts. Use asset.star: asset_hard_link(), asset_soft_link(), etc to create the entries.

    Args:
        name: `str` The name of the rule.
        assets: `[dict]` A list of dict's that define assets to add.
        deps: `[str]` List of dependencies for the rule.
        type: `str` use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        platforms: `[str]` List of [platforms](/docs/builtins/#rule-options) rule applies to.
    """

    info_set_required_semver(">=0.15.19")

    checkout.add_any_assets(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        },
        assets = {"any": assets},
    )

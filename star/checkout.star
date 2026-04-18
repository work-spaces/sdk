"""
User friendly wrapper functions for the spaces checkout built-in functions.
"""

load("asset.star", "asset_home")
load("env.star", "env_assign")
load("info.star", "info_set_minimum_version", "info_set_required_semver")
load("ws.star", "workspace_get_absolute_path", "workspace_get_path_to_home")

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

CHECKOUT_EXPECT_SUCCESS = "Success"
CHECKOUT_EXPECT_FAILURE = "Failure"
CHECKOUT_EXPECT_ANY = "Any"

# This is the only supported value
CHECKOUT_CLONE_TYPE_REVISION = "Revision"

def checkout_add_exec(
        name: str,
        command: str,
        help: str | None = None,
        args: list[str] = [],
        env: dict = {},
        deps: list[str] = [],
        working_directory: str | None = None,
        platforms: list[str] | None = None,
        log_level: str | None = None,
        redirect_stdout: str | None = None,
        timeout: float | None = None,
        visibility: str | dict[str, list[str]] | None = None,
        expect: str = CHECKOUT_EXPECT_SUCCESS):
    """
    Adds a command to the run dependency graph

    Args:
        name: The name of the rule.
        command: The command to execute.
        help: The help message for the rule.
        args: The arguments to pass to the command.
        deps: The rule dependencies that must be run before this command
        env: key value pairs of environment variables
        working_directory: The directory to run the command (default is workspace root).
        platforms: Platforms to run on (default is all).
        log_level: The log level to use None|App|Passthrough
        expect: The expected result of the command Success|Failure|Any. (default is Success)
        redirect_stdout: The file to redirect stdout to (prefer to parse the log file).
        timeout: Number of seconds to run before sending a kill signal.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.
    """

    # checkout.add_exec() introduced in 0.15.22
    info_set_required_semver(">=0.15.22")

    if visibility != None:
        info_set_minimum_version("0.15.24")
    EFFECTIVE_VISIBILITY = {"visibility": visibility} if visibility != None else {}

    checkout.add_exec(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "help": help,
            "type": "Run",
            "inputs": None,
        } | EFFECTIVE_VISIBILITY,
        exec = {
            "command": command,
            "args": args,
            "working_directory": working_directory,
            "env": env,
            "expect": expect,
            "log_level": log_level,
            "redirect_stdout": redirect_stdout,
            "timeout": timeout,
        },
    )

def checkout_get_compile_commands_spaces_name() -> str:
    """
    Returns the name of the file used with checkout_add_compile_commands_dir().

    This is used internally between the checkout rule and compile_commands_merge()
    """
    return "compile_commands.spaces.json"

def checkout_type_optional() -> str:
    """
    Use `checkout_add_repo(type = checkout_type_optional())` to skip checkout

    Returns:
        str: CHECKOUT_TYPE_OPTIONAL
    """
    return CHECKOUT_TYPE_OPTIONAL

def checkout_type_default() -> None:
    """
    Use `checkout_add_repo(type = checkout_type_default())` to use default checkout behavior

    Returns:
        None: CHECKOUT_TYPE_DEFAULT
    """
    return CHECKOUT_TYPE_DEFAULT

def checkout_sparse_mode_cone() -> str:
    """
    Use `checkout_add_repo(sparse_mode = checkout_sparse_mode_cone())` for sparse cone mode.

    Returns:
        str: CHECKOUT_SPARSE_MODE_CONE
    """
    return CHECKOUT_SPARSE_MODE_CONE

def checkout_sparse_mode_no_cone() -> str:
    """
    Use `checkout_add_repo(sparse_mode = checkout_sparse_mode_no_cone())` for sparse no-cone mode.

    This mode uses gitignore-like expressions for sparse checkout.

    Returns:
        str: CHECKOUT_SPARSE_MODE_NO_CONE
    """
    return CHECKOUT_SPARSE_MODE_NO_CONE

def checkout_clone_default() -> str:
    """
    Use `checkout_add_repo(clone = checkout_clone_default())` for a normal git clone.

    Returns:
        str: CHECKOUT_CLONE_DEFAULT
    """
    return CHECKOUT_CLONE_DEFAULT

def checkout_clone_worktree() -> str:
    """
    Use `checkout_add_repo(clone = checkout_clone_worktree())` to store the bare repository in the spaces store.

    Returns:
        str: CHECKOUT_CLONE_WORKTREE
    """
    return CHECKOUT_CLONE_WORKTREE

def checkout_clone_blobless() -> str:
    """
    Use `checkout_add_repo(clone = checkout_clone_blobless())` to filter unused files from the repository history.

    Returns:
        str: CHECKOUT_CLONE_BLOBLESS
    """
    return CHECKOUT_CLONE_BLOBLESS

def checkout_clone_shallow() -> str:
    """
    Use `checkout_add_repo(clone = checkout_clone_shallow())` for a shallow clone.

    Note: The rev must be a branch, not a tag or commit.

    Returns:
        str: CHECKOUT_CLONE_SHALLOW
    """
    return CHECKOUT_CLONE_SHALLOW

def checkout_add_repo(
        name: str,
        url: str,
        rev: str,
        checkout_type: str = CHECKOUT_CLONE_TYPE_REVISION,
        clone: str = CHECKOUT_CLONE_BLOBLESS,
        is_evaluate_spaces_modules: bool | None = None,
        sparse_mode: str | None = None,
        sparse_list: list[str] | None = None,
        working_directory: str | None = None,
        platforms: list[str] | None = None,
        type: str | None = None,
        deps: list[str] = [],
        visibility: str | dict[str, list[str]] | None = None):
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
        name: The name of the rule. This is also the location of the new repo in the workspace.
        url: The git repository URL to clone
        rev: The branch or commit hash to checkout
        checkout_type: Revision
        clone: [checkout_clone_default()](#checkout_clone_default) | [checkout_clone_blobless()](#checkout_clone_blobless) | [checkout_clone_worktree()](#checkout_clone_worktree)
        is_evaluate_spaces_modules: Whether to evaluate spaces.star files in the repo (default is True).
        sparse_mode: Cone | NoCone
        sparse_list: List of paths to include/exclude
        deps: List of dependencies for the rule.
        type: use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        platforms: List of platforms to add the repo to.
        working_directory: The working directory to clone the repository into.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.
    """

    EVALUATE_SPACES_MODULES = {
        "is_evaluate_spaces_modules": is_evaluate_spaces_modules,
    } if is_evaluate_spaces_modules != None else {}
    EFFECTIVE_SPARSE_CHECKOUT = {
        "sparse_checkout": {"mode": sparse_mode, "list": sparse_list},
    } if sparse_mode != None else {}

    if visibility != None:
        info_set_minimum_version("0.15.24")
    EFFECTIVE_VISIBILITY = {"visibility": visibility} if visibility != None else {}

    checkout.add_repo(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        } | EFFECTIVE_VISIBILITY,
        repo = {
            "url": url,
            "rev": rev,
            "checkout": checkout_type,
            "clone": clone,
            "working_directory": working_directory,
        } | EVALUATE_SPACES_MODULES | EFFECTIVE_SPARSE_CHECKOUT,
    )

def checkout_add_archive(
        name: str,
        url: str,
        sha256: str,
        link: str = "Hard",
        includes: list[str] | None = None,
        excludes: list[str] | None = None,
        strip_prefix: str | None = None,
        add_prefix: str = "./",
        filename: str | None = None,
        platforms: list[str] | None = None,
        type: str | None = None,
        headers: dict | None = None,
        deps: list[str] = [],
        visibility: str | dict[str, list[str]] | None = None):
    """
    Adds an archive to the workspace.

    The archive is downloaded to the spaces store and hard-linked to the workspace.

    Args:
        name: The name of the rule.
        url: The URL of the archive to download.
        sha256: The SHA256 checksum of the archive.
        link: Hard | None
        includes: List of globs to include.
        excludes: List of globs to exclude.
        strip_prefix: Prefix to strip from the archive.
        add_prefix: Prefix to add to the archive.
        filename: The filename if it isn't the last part of the URL
        platforms: List of platforms to add the archive to.
        type: use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        headers: key-value pairs of headers to use when downloading the archive.
        deps: List of dependencies for the rule.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.
    """
    if headers != None:
        info_set_required_semver(">=0.15.2")

    effective_headers = {}
    if headers != None:
        effective_headers = {"headers": headers}

    if visibility != None:
        info_set_minimum_version("0.15.24")
    EFFECTIVE_VISIBILITY = {"visibility": visibility} if visibility != None else {}

    checkout.add_archive(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        } | EFFECTIVE_VISIBILITY,
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
        name: str,
        content: str,
        destination: str,
        deps: list[str] = [],
        type: str | None = None,
        platforms: list[str] | None = None,
        visibility: str | dict[str, list[str]] | None = None):
    """
    Adds an asset to the workspace.

    This will create a file in the workspace with the given content as string value.

    Args:
        name: The name of the rule.
        content: The content of the file to create.
        destination: The destination path for the file.
        deps: List of dependencies for the rule.
        type: use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        platforms: List of [platforms](/docs/builtins/#rule-options) to add the archive to.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.
    """
    if visibility != None:
        info_set_minimum_version("0.15.24")
    EFFECTIVE_VISIBILITY = {"visibility": visibility} if visibility != None else {}

    checkout.add_asset(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        } | EFFECTIVE_VISIBILITY,
        asset = {
            "content": content,
            "destination": destination,
        },
    )

def checkout_update_asset(
        name: str,
        destination: str,
        value: dict | list,
        format: str | None = None,
        deps: list[str] = [],
        type: str | None = None,
        platforms: list[str] | None = None,
        visibility: str | dict[str, list[str]] | None = None):
    """
    Updates an asset in the workspace.

    This rule will merge the data of an existing JSON, TOML, or YAML file with the given value.

    Args:
        name: The name of the rule.
        destination: The destination path for the asset.
        format: The format of the asset (json | toml | yaml). Default will get extension from destination.
        value: The value of the asset as a dict to merge with the existing file.
        deps: List of dependencies for the asset.
        type: use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        platforms: List of [platforms](/docs/builtins/#rule-options) to add the archive to.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.
    """

    effective_format = format if format != None else destination.split(".")[-1]

    if visibility != None:
        info_set_minimum_version("0.15.24")
    EFFECTIVE_VISIBILITY = {"visibility": visibility} if visibility != None else {}

    checkout.update_asset(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        } | EFFECTIVE_VISIBILITY,
        asset = {
            "destination": destination,
            "format": effective_format,
            "value": value,
        },
    )

def checkout_add_cargo_bin(
        name: str,
        crate: str,
        version: str,
        bins: list[str],
        deps: list[str] = [],
        type: str | None = None,
        platforms: list[str] | None = None,
        visibility: str | dict[str, list[str]] | None = None):
    """
    Adds a cargo binary to the workspace.

    Args:
        name: The name of the rule.
        crate: The name of the crate.
        version: The version of the crate.
        bins: List of binaries to add.
        deps: List of dependencies for the rule.
        type: use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        platforms: List of [platforms](/docs/builtins/#rule-options) to add the archive to.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.
    """
    if visibility != None:
        info_set_minimum_version("0.15.24")
    EFFECTIVE_VISIBILITY = {"visibility": visibility} if visibility != None else {}

    checkout.add_cargo_bin(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        } | EFFECTIVE_VISIBILITY,
        cargo_bin = {
            "crate": crate,
            "version": version,
            "bins": bins,
        },
    )

def checkout_add_hard_link_asset(
        name: str,
        source: str,
        destination: str,
        deps: list[str] = [],
        type: str | None = None,
        platforms: list[str] | None = None,
        visibility: str | dict[str, list[str]] | None = None):
    """
    Adds a hard link asset to the workspace.

    Args:
        name: The name of the rule.
        source: The source path of the asset.
        destination: The destination path for the asset.
        deps: List of dependencies for the asset.
        type: use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        platforms: List of [platforms](/docs/builtins/#rule-options) to add the archive to.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.
    """
    if visibility != None:
        info_set_minimum_version("0.15.24")
    EFFECTIVE_VISIBILITY = {"visibility": visibility} if visibility != None else {}

    checkout.add_hard_link_asset(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        } | EFFECTIVE_VISIBILITY,
        asset = {
            "source": source,
            "destination": destination,
        },
    )

def checkout_add_soft_link_asset(
        name: str,
        source: str,
        destination: str,
        deps: list[str] = [],
        type: str | None = None,
        platforms: list[str] | None = None,
        visibility: str | dict[str, list[str]] | None = None):
    """
    Adds a soft link asset to the workspace.

    Args:
        name: The name of the rule.
        source: The source path of the soft link.
        destination: The relative workspace path of the soft link destination.
        deps: List of dependencies for the asset.
        type: use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        platforms: List of [platforms](/docs/builtins/#rule-options) to add the archive to.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.
    """
    if visibility != None:
        info_set_minimum_version("0.15.24")
    EFFECTIVE_VISIBILITY = {"visibility": visibility} if visibility != None else {}

    checkout.add_soft_link_asset(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        } | EFFECTIVE_VISIBILITY,
        asset = {
            "source": source,
            "destination": destination,
        },
    )

def checkout_add_target(
        name: str,
        deps: list[str],
        type: str | None = None,
        platforms: list[str] | None = None,
        visibility: str | dict[str, list[str]] | None = None):
    """
    Adds a target to the workspace.

    Args:
        name: The name of the rule.
        deps: List of dependencies for the target.
        type: use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        platforms: List of [platforms](/docs/builtins/#rule-options) to add the archive to.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.
    """
    if visibility != None:
        info_set_minimum_version("0.15.24")
    EFFECTIVE_VISIBILITY = {"visibility": visibility} if visibility != None else {}

    checkout.add_target(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        } | EFFECTIVE_VISIBILITY,
    )

def checkout_add_platform_archive(
        name: str,
        platforms: dict,
        deps: list[str] = [],
        type: str | None = None,
        visibility: str | dict[str, list[str]] | None = None):
    """
    Adds a platform archive to the checkout.

    Platform archives are used to add binary tools based on the host platform.

    Args:
        name: The name of the rule.
        platforms: List of [platforms](/docs/builtins/#rule-options) to add the archive to.
        deps: List of dependencies for the rule.
        type: use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        visibility: Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.
    """
    if visibility != None:
        info_set_minimum_version("0.15.24")
    EFFECTIVE_VISIBILITY = {"visibility": visibility} if visibility != None else {}

    checkout.add_platform_archive(
        rule = {"name": name, "type": type, "deps": deps} | EFFECTIVE_VISIBILITY,
        platforms = platforms,
    )

def checkout_update_env(
        name: str,
        vars: dict = {},
        paths: list[str] = [],
        system_paths: list[str] | None = None,
        inherited_vars: list[str] | None = None,
        optional_inherited_vars: list[str] | None = None,
        run_inherited_vars: list[str] | None = None,
        secret_inherited_vars: list[str] | None = None,
        deps: list[str] = [],
        type: str | None = None,
        platforms: list[str] | None = None,
        visibility: str | dict[str, list[str]] | None = None):
    """
    Updates the environment with the given variables and paths.

    Variables other than PATH are added as key/value pairs. PATH is added as a list of values. The order
    of the PATHS is based on execution order which can be controlled using `deps`. The `system_paths`
    are added after the `paths` values.

    All vars are fixed at checkout time except vars specified in `run_inherited_vars`. Checkout vars
    are stored in the new workspace in `env.spaces.star`. `run_inherited_vars` are inherited when executing `spaces run`.
    `secret_inherited_vars` are inherited when executing spaces checkout or run. The values of the secrets are masked in the logs and terminal.

    Args:
        name: The name of the rule.
        vars: Dictionary of variables to store in `env.spaces.star`.
        paths: List of paths to add to the PATH.
        system_paths: The path to add to the system PATH.
        inherited_vars: List of variables to inherit from the calling environment and store in `env.spaces.star`.
        optional_inherited_vars: List of variables to inherit from the calling environment if they exist and store in `env.spaces.star` (requires spaces >v0.15.1)
        run_inherited_vars: List of variables inherited when executing spaces run.
        secret_inherited_vars: List of variables inherited when executing spaces checkout/run. Values will be masked in the logs and terminal.
        deps: List of dependencies for the rule.
        type: use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        platforms: List of [platforms](/docs/builtins/#rule-options) to add the archive to.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.
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

    if visibility != None:
        info_set_minimum_version("0.15.24")
    EFFECTIVE_VISIBILITY = {"visibility": visibility} if visibility != None else {}

    checkout.update_env(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        } | EFFECTIVE_VISIBILITY,
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
        name: str,
        which: str,
        destination: str,
        deps: list[str] = [],
        platforms: list[str] | None = None,
        type: str | None = None,
        visibility: str | dict[str, list[str]] | None = None):
    """
    Adds an asset to the destintion based on the which command.

    Using this function creates system dependencies that may not be reproducible across different systems.

    Args:
        name: The name of the rule.
        which: The name of the asset to add.
        destination: The destination path for the asset.
        deps: List of dependencies for the asset.
        type: use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        platforms: List of [platforms](/docs/builtins/#rule-options) to add the archive to.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.
    """

    if visibility != None:
        info_set_minimum_version("0.15.24")
    EFFECTIVE_VISIBILITY = {"visibility": visibility} if visibility != None else {}

    checkout.add_which_asset(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        } | EFFECTIVE_VISIBILITY,
        asset = {
            "which": which,
            "destination": destination,
        },
    )

def update_platforms_prefix(
        platforms: dict,
        add_prefix: str) -> dict:
    """
    Updates the prefix of the platforms.

    Args:
        platforms: List of [platforms](/docs/builtins/#rule-options) to add the archive to.
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
        name: str,
        url: str,
        artifact: str,
        tag: str,
        add_prefix: str,
        manifest_digest_path: str = "/layers/0/digest",
        manifest_artifact_path: str = "/layers/0/annotations/org.opencontainers.image.title",
        globs: list[str] | None = None,
        deps: list[str] = [],
        type: str | None = None,
        platforms: list[str] | None = None,
        visibility: str | dict[str, list[str]] | None = None):
    """
    Adds an oras archive to the workspace.

    Args:
        name: The name of the rule.
        url: The URL of the oras archive to download.
        artifact: The artifact name of the oras archive.
        tag: The tag of the oras archive.
        add_prefix: The prefix to add to the archive.
        manifest_digest_path: The path to the manifest digest in the oras archive.
        manifest_artifact_path: The path to the manifest artifact in the oras archive.
        globs: List of globs to include/exclude.
        deps: List of dependencies for the rule.
        type: use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        platforms: List of [platforms](/docs/builtins/#rule-options) to add the archive to.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.
    """

    if visibility != None:
        info_set_minimum_version("0.15.24")
    EFFECTIVE_VISIBILITY = {"visibility": visibility} if visibility != None else {}

    checkout.add_oras_archive(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        } | EFFECTIVE_VISIBILITY,
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

def checkout_add_compile_commands_dir(name: str, path: str, rule: str):
    """
    Registers a build directory in the compile_commands.spaces.json file.

    Args:
        name: The name of the checkout rule.
        path: The path to the build directory where compile_commands.json will be found.
        rule: The name of the rule that is associated with creating the compile_command.json file.
    """

    checkout_update_asset(
        name,
        destination = checkout_get_compile_commands_spaces_name(),
        value = {"{}".format(path): "{}".format(rule)},
    )

def checkout_update_shell(name: str, shell_path: str, args: list[str] = [], deps: list[str] = [], visibility: str | dict[str, list[str]] | None = None):
    """

    Updates the workspace shell configuration that is used with `spaces shell`

    Args:
        name: The name of the rule.
        shell_path: The path to the shell executable.
        args: The arguments to pass to the shell.
        deps: The dependencies of the rule (allows controlling order of updating the file)
        visibility: The visibility of the rule.
        """
    checkout_update_asset(
        name,
        destination = _CHECKOUT_SHELL_SPACES_TOML,
        value = {
            "path": shell_path,
            "args": args,
        },
        deps = deps,
        visibility = visibility,
    )

def checkout_update_shell_startup(
        name: str,
        script_name: str,
        contents: str,
        env_name: str | None = None,
        deps: list[str] = [],
        visibility: str | dict[str, list[str]] | None = None):
    """

    Updates the workspace shell configuration that is used with `spaces shell`

    Args:
        name: The name of the rule.
        script_name: The name of the startup file to generate and store at `.spaces/shell/<script_name>` in the workspace.
        contents: The contents of the startup file.
        env_name: If not None, this will be set to point to the workspace shell startup directory `.spaces/shell`.
        deps: The dependencies of the rule (allows controlling order of updating the file)
        visibility: The visibility of the rule (allows controlling who can see the rule)
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
        visibility = visibility,
    )

def checkout_update_shell_shortcuts(name: str, shortcuts: dict, deps: list[str] = [], visibility: str | dict[str, list[str]] | None = None):
    """

    Updates the `.spaces/shell/shortcuts.sh` file with shell functions. This file can be source when starting the shell.

    Args:
        name: The name of the rule.
        shortcuts: A dictionary of function names (key) and shell commands to execute (values).
        deps: A list of dependencies that allows override of shortcuts.
        visibility: The visibility of the rule (allows controlling who can see the rule)
    """
    if shortcuts != None:
        checkout_update_asset(
            name,
            destination = _CHECKOUT_SHELL_SPACES_TOML,
            value = {
                "shortcuts": shortcuts,
            },
            deps = deps,
            visibility = visibility,
        )

def checkout_add_any_assets(
        name: str,
        assets: list[dict],
        deps: list[str] = [],
        type: str | None = None,
        platforms: list[str] | None = None,
        visibility: str | dict[str, list[str]] | None = None):
    """
    Adds a list of any assets to the workspace as a single rule.

    `assets` should be a list of dicts. Use asset.star: asset_hard_link(), asset_soft_link(), etc to create the entries.

    Args:
        name: The name of the rule.
        assets: A list of dict's that define assets to add.
        deps: List of dependencies for the rule.
        type: use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        platforms: List of [platforms](/docs/builtins/#rule-options) rule applies to.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.
    """

    info_set_required_semver(">=0.15.19")

    if visibility != None:
        info_set_minimum_version("0.15.24")
    EFFECTIVE_VISIBILITY = {"visibility": visibility} if visibility != None else {}

    checkout.add_any_assets(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
        } | EFFECTIVE_VISIBILITY,
        assets = {"any": assets},
    )

def checkout_add_env_vars(
        name: str,
        vars: list[dict],
        deps: list[str] = [],
        type: str | None = None,
        platforms: list[str] | None = None,
        visibility: str | dict[str, list[str]] | None = None):
    """
    Adds environment variables to the workspace.

    Args:
        name: Name of the checkout rule
        vars: list of env objects from env.star
        deps: List of dependencies for the rule.
        type: use [checkout_type_optional()](#checkout_type_optional) to skip rule checkout
        platforms: List of [platforms](/docs/builtins/#rule-options) rule applies to.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.
    """

    info_set_minimum_version("0.15.27")

    checkout.add_env_vars(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
            "visibility": visibility,
        },
        any_env = {
            "vars": vars,
        },
    )

def checkout_store_value(name: str, value):
    """
    Stores a value that can be retrieved using workspace_load_value().

    Values are persisted across checkout and run phases, allowing data
    computed during checkout to be accessed later. The value can be any
    serializable type (dict, list, string, int, float, bool, or None).

    Args:
        name: The key to store the value under.
        value: The value to store. Can be any type.
    """

    checkout.store_value(name, value)

def checkout_add_home_store_env(name: str):
    """
    Assigns HOME to a user specific location in the spaces store.

    Args:
        name: Name of the checkout rule
    """

    checkout_add_env_vars(
        name,
        vars = [
            env_assign(
                "HOME",
                workspace_get_absolute_path() + "/" + workspace_get_path_to_home(),
                help = "Assigns HOME to a user specific location in the spaces store",
            ),
        ],
    )

def checkout_add_home_assets(name: str, assets: list[str]):
    """
    Adds home assets to the workspace.

    Each entry in `assets` is a path relative to $HOME. The file is copied into the spaces store
    under .spaces/store/home/$USER/<source> and hard-linked into the workspace at the same relative path.

    Args:
        name: Name of the checkout rule
        assets: list of paths relative to $HOME (e.g. [".ssh/config"])
    """
    info_set_minimum_version("0.15.35")

    checkout_add_any_assets(
        name,
        assets = [asset_home(source) for source in assets],
    )

def checkout_set_sandbox(sandbox: dict):
    """
    Sets the sandbox configuration for the workspace.

    This configuration defines the base sandbox for the workspace.

    Use sandbox.star to define the sandbox configuration.

    Args:
        sandbox: The sandbox configuration to set (use sandbox.star)
    """
    return checkout.set_sandbox(sandbox = sandbox)

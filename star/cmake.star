"""
Add CMake to your sysroot.
"""

load(
    "checkout.star",
    "CHECKOUT_TYPE_OPTIONAL",
    "checkout_add_archive",
    "checkout_add_repo",
)
load("run.star", "run_add_exec", "run_add_target")
load("ws.star", "workspace_get_absolute_path")

def cmake_get_default_prefix_paths(install_path = None):
    """
    Get the default prefix paths for CMake

    Args:
        install_path: The path to install the project

    Returns:
        A list of the default prefix paths
    """
    WORKSPACE = workspace_get_absolute_path()
    locations = [install_path] if install_path != None else ["{}/build/install".format(WORKSPACE)]
    locations.append("{}/sysroot".format(WORKSPACE))
    return locations

def cmake_add_configure_build_install(
        name,
        source_directory,
        build_directory = None,
        prefix_paths = None,
        configure_inputs = None,
        build_inputs = None,
        configure_args = [],
        build_args = [],
        build_artifact_globs = None,
        deps = [],
        install_path = None,
        skip_install = False):
    """
    Add a CMake project to the build

    Args:
        name: The name of the project
        build_directory: The directory to build the project in (default is build/<name>)
        source_directory: The directory of the project
        configure_inputs: The inputs for the configure step. Default uses cmake files in source directory
        build_inputs: The inputs for the build step. Default uses source directory
        prefix_paths: The paths to add to the CMAKE_PREFIX_PATH: default is sysroot;build/install (uses absolute paths)
        configure_args: The arguments to pass to the configure script
        build_args: The arguments to pass to the build command
        build_artifact_globs: The globs to match when installing build artifacts
        deps: The dependencies of the project
        install_path: The path to install the project
        skip_install: Skip the install step
    """

    CONFIGURE_RULE_NAME = "{}_configure".format(name)
    BUILD_RULE_NAME = "{}_build".format(name)
    INSTALL_RULE_NAME = "{}_install".format(name)
    WORKSPACE = workspace_get_absolute_path()
    EFFECTIVE_INSTALL_PATH = install_path if install_path != None else "{}/build/install".format(WORKSPACE)
    INSTALL_PREFIX_ARG = "-DCMAKE_INSTALL_PREFIX={}".format(EFFECTIVE_INSTALL_PATH)
    DEFAULT_PREFIX_PATHS = cmake_get_default_prefix_paths(install_path)
    effective_prefix_paths = DEFAULT_PREFIX_PATHS
    if prefix_paths != None:
        effective_prefix_paths = prefix_paths

    prefix_arg = "-DCMAKE_PREFIX_PATH={}".format(";".join(effective_prefix_paths))
    EFFECTIVE_BUILD_DIRECTORY = build_directory if build_directory != None else "build/{}".format(name)

    DEFAULT_CONFIGURE_INPUTS = [
        "+//{}/**/CMakeLists.txt".format(source_directory),
        "+//{}/**/*.cmake".format(source_directory),
    ]

    EFFECTIVE_CONFIGURE_INPUTS = configure_inputs if configure_inputs != None else DEFAULT_CONFIGURE_INPUTS

    DEFAULT_BUILD_INPUTS = [
        "+//{}/**".format(source_directory),
    ]
    EFFECTIVE_BUILD_INPUTS = build_inputs if build_inputs != None else DEFAULT_BUILD_INPUTS

    run_add_exec(
        CONFIGURE_RULE_NAME,
        command = "cmake",
        deps = deps,
        inputs = EFFECTIVE_CONFIGURE_INPUTS,
        args = [
            INSTALL_PREFIX_ARG,
            prefix_arg,
            "-DCMAKE_FIND_USE_CMAKE_SYSTEM_PATH=FALSE",
            "-B{}".format(EFFECTIVE_BUILD_DIRECTORY),
            "-S{}".format(source_directory),
        ] + configure_args,
        help = "CMake Configure:{}".format(name),
    )

    run_add_exec(
        BUILD_RULE_NAME,
        command = "cmake",
        inputs = EFFECTIVE_BUILD_INPUTS,
        deps = [CONFIGURE_RULE_NAME],
        args = ["--build", EFFECTIVE_BUILD_DIRECTORY] + build_args,
        help = "CMake build:{}".format(name),
    )

    name_dep = BUILD_RULE_NAME
    if not skip_install:
        run_add_exec(
            INSTALL_RULE_NAME,
            inputs = build_artifact_globs,
            command = "cmake",
            deps = [BUILD_RULE_NAME],
            args = ["--build", EFFECTIVE_BUILD_DIRECTORY, "--target", "install"],
            help = "CMake install:{}".format(name),
        )
        name_dep = INSTALL_RULE_NAME

    run_add_target(
        name,
        deps = [name_dep],
        help = "CMake configure/build/install",
    )

def cmake_add_repo(
        name,
        url,
        rev,
        install_path = None,
        configure_args = [],
        build_args = [],
        build_artifact_globs = [],
        checkout_submodules = False,
        relative_source_directory = None,
        clone = "Worktree",
        checkout_type = None,
        skip_install = False,
        deps = []):
    """
    Add a CMake project to the build

    Args:
        name: The name of the project
        url: The URL of the repository
        rev: The revision of the repository
        install_path: The path to install the project
        configure_args: The arguments to pass to the configure script
        build_args: The arguments to pass to the build command
        build_artifact_globs: The globs to match when installing build artifacts
        checkout_submodules: Whether to checkout submodules
        relative_source_directory: The directory of the project (default is the name)
        clone: The clone type (Worktree, Blobless, Shallow, Default)
        checkout_type: `str` use [checkout_type_optional()](#/docs/@star/sdk/star/checkout#checkout_type_optional) to skip rule checkout
        skip_install: Skip the install step
        deps: The dependencies of the project
    """

    CHECKOUT_RULE = "{}_source".format(name)
    checkout_add_repo(
        CHECKOUT_RULE,
        url = url,
        rev = rev,
        clone = clone,
        type = checkout_type,
    )

    if not checkout_type == CHECKOUT_TYPE_OPTIONAL:
        SUBMODULE_RULE = "{}_submodules".format(name)
        SUBMODULE_DEPS = []
        if checkout_submodules:
            run_add_exec(
                SUBMODULE_RULE,
                command = "git",
                args = ["submodule", "update", "--init", "--recursive"],
                working_directory = "//{}".format(CHECKOUT_RULE),
            )
            SUBMODULE_DEPS = [SUBMODULE_RULE]

        source_directory = "{}/{}".format(CHECKOUT_RULE, relative_source_directory) if relative_source_directory != None else CHECKOUT_RULE

        cmake_add_configure_build_install(
            name,
            source_directory = source_directory,
            configure_args = configure_args,
            build_args = build_args,
            build_artifact_globs = build_artifact_globs,
            deps = deps + SUBMODULE_DEPS,
            install_path = install_path,
            skip_install = skip_install,
        )

def cmake_add_source_archive(
        name,
        url,
        sha256,
        source_directory,
        filename = None,
        install_path = None,
        configure_args = [],
        build_args = [],
        build_artifact_globs = None,
        deps = [],
        checkout_type = None,
        skip_install = False):
    """
    Add a CMake project to the build

    Args:
        name: `str` The name of the project
        url: `str` The URL of the source archive
        sha256: `str` The SHA256 of the source archive
        source_directory: `str` The directory of the project
        filename: `str` The filename of the source archive
        install_path: `str` The path to install the project
        configure_args: `[str]` The arguments to pass to the configure script
        build_args: `[str]` The arguments to pass to the build command
        build_artifact_globs: `[str]` The globs to match when installing build artifacts
        deps: `[str]` List of dependencies of the project
        checkout_type: `str` use [checkout_type_optional()](#/docs/@star/sdk/star/checkout#checkout_type_optional) to skip rule checkout
        skip_install: Skip the install step
    """

    checkout_add_archive(
        "{}_source".format(name),
        url = url,
        sha256 = sha256,
        filename = filename,
        type = checkout_type,
    )

    if not checkout_type == CHECKOUT_TYPE_OPTIONAL:
        cmake_add_configure_build_install(
            name,
            source_directory,
            configure_args = configure_args,
            build_args = build_args,
            install_path = install_path,
            deps = deps,
            build_artifact_globs = build_artifact_globs,
            skip_install = skip_install,
        )

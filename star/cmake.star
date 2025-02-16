"""
Add CMake to your sysroot.
"""

load(
    "checkout.star",
    "checkout_add_archive",
    "checkout_add_repo",
    "CHECKOUT_TYPE_OPTIONAL"
)
load("run.star", "run_add_exec", "run_add_target")

def cmake_add_configure_build_install(
        name,
        source_directory,
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
        source_directory: The directory of the project
        configure_args: The arguments to pass to the configure script
        build_args: The arguments to pass to the build command
        build_artifact_globs: The globs to match when installing build artifacts
        deps: The dependencies of the project
        install_path: The path to install the project
        skip_install: Skip the install step
    """

    configure_rule_name = "{}_configure".format(name)
    build_rule_name = "{}_build".format(name)
    install_rule_name = "{}_install".format(name)
    workspace = info.get_absolute_path_to_workspace()

    effective_install_path = install_path if install_path != None else "{}/build/install".format(workspace)
    install_prefix_arg = "-DCMAKE_INSTALL_PREFIX={}".format(effective_install_path)
    prefix_arg = "-DCMAKE_PREFIX_PATH={};{}/sysroot;{}/build/install".format(effective_install_path, workspace, workspace)
    working_directory = "build/{}".format(name)

    run_add_exec(
        configure_rule_name,
        command = "cmake",
        deps = deps,
        inputs = [
            "+{}/**/CMakeLists.txt".format(source_directory),
            "+{}/**/*.cmake".format(source_directory),
            "-{}/.git/**".format(source_directory),
        ],
        args = [
            install_prefix_arg,
            prefix_arg,
            "-DCMAKE_FIND_USE_CMAKE_SYSTEM_PATH=FALSE",
            "-B{}".format(working_directory),
            "-S{}".format(source_directory),
        ] + configure_args,
        help = "CMake Configure:{}".format(name),
    )

    run_add_exec(
        build_rule_name,
        command = "cmake",
        inputs = ["+{}/**".format(source_directory)],
        deps = [configure_rule_name],
        args = ["--build", working_directory] + build_args,
        help = "CMake build:{}".format(name),
    )

    if not skip_install:
        run_add_exec(
            install_rule_name,
            inputs = build_artifact_globs,
            command = "cmake",
            deps = [build_rule_name],
            args = ["--build", working_directory, "--target", "install"],
            help = "CMake install:{}".format(name),
        )
        run_add_target(name, deps = [install_rule_name])
    else:
        run_add_target(name, deps = [build_rule_name])    

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
        checkout_type: Use CHECKOUT_TYPE_OPTIONAL to make the checkout optional
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
                working_directory = CHECKOUT_RULE,
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
        name: The name of the project
        url: The URL of the source archive
        sha256: The SHA256 of the source archive
        source_directory: The directory of the project
        filename: The filename of the source archive
        install_path: The path to install the project
        configure_args: The arguments to pass to the configure script
        build_args: The arguments to pass to the build command
        build_artifact_globs: The globs to match when installing build artifacts
        deps: The dependencies of the project
        checkout_type: Use CHECKOUT_TYPE_OPTIONAL to make the checkout optional
        skip_install: Skip the install step
    """

    checkout_add_archive(
        "{}_source".format(name),
        url = url,
        sha256 = sha256,
        filename = filename,
        type = checkout_type
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
            skip_install = skip_install
        )

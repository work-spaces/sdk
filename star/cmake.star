"""
Add CMake to your sysroot.
"""

load(
    "checkout.star",
    "checkout_add_archive",
    "checkout_add_repo",
)
load(
    "capsule.star",
    "capsule_add_checkout_and_run",
)
load("run.star", "run_add_exec", "run_add_target")

def cmake_add_configure_build_install(
        name,
        source_directory,
        configure_args = [],
        build_args = [],
        build_artifact_globs = [],
        deps = [],
        install_path = None,
        type = None,
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
        type: rule type (Use Optional or none to include with all)
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
        type = type,
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
        type = type,
        inputs = ["+{}/**".format(source_directory)],
        deps = [configure_rule_name],
        args = ["--build", working_directory] + build_args,
        help = "CMake build:{}".format(name),
    )

    if not skip_install:
        run_add_exec(
            install_rule_name,
            inputs = build_artifact_globs,
            type = type,
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
        type = None,
        configure_args = [],
        build_args = [],
        build_artifact_globs = [],
        checkout_submodules = False,
        relative_source_directory = None,
        clone = "Worktree",
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
        type: rule type (Use Optional or none to include with all)
        build_artifact_globs: The globs to match when installing build artifacts
        checkout_submodules: Whether to checkout submodules
        relative_source_directory: The directory of the project (default is the name)
        clone: The clone type (Worktree, Blobless, Shallow, Default)
        skip_install: Skip the install step
        deps: The dependencies of the project
    """

    checkout_rule = "{}_source".format(name)
    checkout_add_repo(
        checkout_rule,
        url = url,
        rev = rev,
        clone = clone,
    )

    submodule_rule = "{}_submodules".format(name)
    submodule_deps = []
    if checkout_submodules:
        run_add_exec(
            submodule_rule,
            type = type,
            command = "git",
            args = ["submodule", "update", "--init", "--recursive"],
            working_directory = checkout_rule,
        )
        submodule_deps = [submodule_rule]

    source_directory = "{}/{}".format(checkout_rule, relative_source_directory) if relative_source_directory != None else checkout_rule

    cmake_add_configure_build_install(
        name,
        source_directory = source_directory,
        configure_args = configure_args,
        build_args = build_args,
        build_artifact_globs = build_artifact_globs,
        deps = deps + submodule_deps,
        install_path = install_path,
        skip_install = skip_install,
        type = type
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
        build_artifact_globs = [],
        deps = [],
        type = None,
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
        type: rule type (Use Optional or none to include with all)
        skip_install: Skip the install step
    """

    checkout_add_archive(
        "{}_source".format(name),
        url = url,
        sha256 = sha256,
        filename = filename,
    )

    cmake_add_configure_build_install(
        name,
        source_directory,
        configure_args = configure_args,
        build_args = build_args,
        install_path = install_path,
        deps = deps,
        build_artifact_globs = build_artifact_globs,
        type = type,
        skip_install = skip_install
    )

def cmake_capsule_add_repo_checkout_and_run(
        name,
        capsule,
        rev,
        version,
        checkout_function = None,
        source_url = None,
        oras_url = None,
        gh_deploy_repo = None,
        suffix = "tar.gz",
        configure_args = [],
        build_args = [],
        checkout_submodules = False,
        relative_source_directory = None):
    """
    Add the checkout and run if the install path does not exist

    Args:
        name: The rule name
        capsule: return value of capsule()
        rev: The commit/rev of the repository
        version: The version of the repository
        checkout_function: Function is called to checkout build tools if a build is required
        source_url: The URL of the repository (built from domain, owner, and repo if not provided)
        oras_url: The URL of the oras repo to use for the capsule
        gh_deploy_repo: The gh repository to deploy the capsule to
        suffix: The suffix of the archive file (tar.gz, tar.xz, tar.bz2, zip)
        configure_args: The arguments to pass to the configure script
        build_args: The arguments to pass to the build command
        checkout_submodules: Whether to checkout submodules
        relative_source_directory: The directory to set `-S<source_directory>` when configuraing CMake (default is where repo is checked out)
    """

    effective_url = source_url if source_url != None else "https://{}/{}/{}".format(capsule["domain"], capsule["owner"], capsule["repo"])

    def build_function(name, install_path, args):

        if args["checkout_function"] != None:
            args["checkout_function"](install_path)

        cmake_add_repo(
            name,
            url = args["url"],
            rev = args["rev"],
            install_path = install_path,
            configure_args = args["configure_args"],
            build_args = args["build_args"],
            relative_source_directory = args["relative_source_directory"],
            checkout_submodules = args["checkout_submodules"]
        )

    capsule_add_checkout_and_run(
        name,
        capsule = capsule,
        version = version,
        oras_url = oras_url,
        suffix = suffix,
        gh_deploy_repo = gh_deploy_repo,
        build_function = build_function,
        build_function_args = {
            "url": effective_url,
            "version": version,
            "rev": rev,
            "relative_source_directory": relative_source_directory,
            "configure_args": configure_args,
            "build_args": build_args,
            "checkout_submodules": checkout_submodules,
            "checkout_function": checkout_function,
        },
    )

def cmake_capsule_add_archive_checkout_and_run(
        name,
        capsule,
        version,
        url,
        sha256,
        source_directory,
        filename = None,
        oras_url = None,
        gh_deploy_repo = None,
        suffix = "tar.gz",
        configure_args = [],
        build_args = []):
    """
    Add the checkout and run if the install path does not exist

    Args:
        name: The name of the capsule
        capsule: The capsule descriptor
        version: The version of the repository
        url: The URL of the repository (built from domain, owner, and repo if not provided)
        sha256: The SHA256 of the archive
        source_directory: The directory of the project
        filename: The filename if the URL does not end in the filename
        oras_url: The URL of the oras repo to use for the capsule
        gh_deploy_repo: The repository to deploy the capsule to
        suffix: The suffix of the archive file (tar.gz, tar.xz, tar.bz2, zip)
        configure_args: The arguments to pass to the configure script
        build_args: The arguments to pass to the build command
    """

    def build_function(name, install_path, args):
        cmake_add_source_archive(
            name,
            source_directory = args["source_directory"],
            url = args["url"],
            sha256 = args["sha256"],
            filename = args["filename"],
            install_path = install_path,
            configure_args = args["configure_args"],
            build_args = args["build_args"],
        )

    capsule_add_checkout_and_run(
        name,
        capsule = capsule,
        version = version,
        oras_url = oras_url,
        gh_deploy_repo = gh_deploy_repo,
        build_function = build_function,
        suffix = suffix,
        build_function_args = {
            "url": url,
            "sha256": sha256,
            "version": version,
            "source_directory": source_directory,
            "filename": filename,
            "configure_args": configure_args,
            "build_args": build_args,
        },
    )

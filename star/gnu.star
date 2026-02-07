"""
GNU Build Functions
"""

load("checkout.star", "checkout_add_repo")
load("info.star", "info_get_cpu_count")
load("run.star", "run_add_exec", "run_add_target")
load("ws.star", "workspace_get_absolute_path")

def gnu_add_configure_make_install(
        name,
        source_directory,
        autoreconf_args = None,
        configure_args = [],
        make_args = [],
        build_artifact_globs = None,
        deps = [],
        install_path = None,
        skip_install = False,
        env = {}):
    """
    Add an autotools project to the build

    Args:
        name: `str` The name of the project
        source_directory: `str` The directory of the project
        autoreconf_args: `[str]` The arguments to pass to the autoreconf script
        configure_args: `[str]` The arguments to pass to the configure script
        make_args: `[str]` The arguments to pass to the make command
        build_artifact_globs: `[str]` The globs to match the build artifacts
        deps: `[str]` The dependencies of the project
        install_path: `str` The path to install the project
        skip_install: `bool` Whether to skip the install step
        env: `dict` The environment variables to set during configure, build, and install
    """

    BUILD_DIR = "build/{}".format(name)
    WORKING_BUILD_DIR = "//{}".format(BUILD_DIR)
    PREPARE_RULE_NAME = "{}_prepare".format(name)
    AUTORECONF_RULE_NAME = "{}_autoreconf".format(name)
    CONFIGURE_RULE_NAME = "{}_configure".format(name)
    BUILD_RULE_NAME = "{}_build".format(name)
    INSTALL_RULE_NAME = "{}_install".format(name)
    WORKSPACE = workspace_get_absolute_path()
    EFFECTIVE_INSTALL_PATH = install_path if install_path != None else "build/install"
    PREFIX_ARG = "--prefix={}/{}".format(WORKSPACE, EFFECTIVE_INSTALL_PATH)
    NUM_CPUS = info_get_cpu_count()

    run_add_exec(
        PREPARE_RULE_NAME,
        command = "mkdir",
        args = ["-p", BUILD_DIR],
        env = env,
    )

    autoreconf_deps = [PREPARE_RULE_NAME]
    if autoreconf_args:
        run_add_exec(
            AUTORECONF_RULE_NAME,
            deps = [PREPARE_RULE_NAME] + deps,
            inputs = ["+//{}/configure.ac".format(source_directory)],
            command = "autoreconf",
            args = autoreconf_args,
            working_directory = source_directory,
            help = "autoreconf {}".format(name),
            env = env,
        )
        autoreconf_deps = [AUTORECONF_RULE_NAME]

    run_add_exec(
        CONFIGURE_RULE_NAME,
        deps = autoreconf_deps + deps,
        inputs = ["+//{}/configure".format(source_directory)],
        command = "../../{}/configure".format(source_directory),
        args = [PREFIX_ARG] + configure_args,
        working_directory = WORKING_BUILD_DIR,
        help = "Configure {}".format(name),
        env = env,
    )

    run_add_exec(
        BUILD_RULE_NAME,
        deps = [CONFIGURE_RULE_NAME],
        inputs = [
            "+//{}/Makefile".format(BUILD_DIR),
            "+//{}/**".format(source_directory),
        ],
        command = "make",
        args = ["-j{}".format(NUM_CPUS)] + make_args,
        working_directory = WORKING_BUILD_DIR,
        help = "Build {}".format(name),
        env = env,
    )

    if skip_install:
        run_add_target(name, deps = [BUILD_RULE_NAME])
        return

    run_add_exec(
        INSTALL_RULE_NAME,
        deps = [BUILD_RULE_NAME],
        inputs = build_artifact_globs,
        command = "make",
        args = ["install"],
        working_directory = WORKING_BUILD_DIR,
        help = "Install {}".format(name),
        env = env,
    )

    run_add_target(name, deps = [INSTALL_RULE_NAME])

def gnu_add_repo(
        name,
        url,
        rev,
        autoreconf_args = None,
        configure_args = [],
        make_args = [],
        checkout_submodules = False,
        deps = [],
        install_path = None,
        env = {}):
    """
    Add an autotools project from a repository

    Args:
        name: `str` The name of the project
        url: `str` The URL of the repository
        rev: `str` The revision of the repository
        autoreconf_args: `[str]` The arguments to pass to the autoreconf script
        configure_args: `[str]` The arguments to pass to the configure script
        make_args: `[str]` The arguments to pass to the make
        checkout_submodules: `bool` Whether to checkout submodules
        deps: `[str]` The dependencies of the project
        install_path: `str` The path to install the project
        env: `dict` The environment variables to set during configure, make, and install
    """

    CHECKOUT_RULE = "{}_source".format(name)
    checkout_add_repo(
        CHECKOUT_RULE,
        url = url,
        rev = rev,
        clone = "Blobless",
    )

    SUBMODULE_RULE = "{}_submodules".format(name)
    submodule_deps = []
    if checkout_submodules:
        run_add_exec(
            "{}_submodules".format(name),
            command = "git",
            args = ["submodule", "update", "--init", "--recursive"],
            working_directory = "//{}".format(CHECKOUT_RULE),
        )
        submodule_deps = [SUBMODULE_RULE]

    gnu_add_configure_make_install(
        name,
        source_directory = CHECKOUT_RULE,
        autoreconf_args = autoreconf_args,
        configure_args = configure_args,
        make_args = make_args,
        deps = deps + submodule_deps,
        install_path = install_path,
        env = env,
    )

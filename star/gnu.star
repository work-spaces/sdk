"""
GNU Build Functions
"""

load("run.star", "run_add_exec", "run_add_target")
load("checkout.star", "checkout_add_repo")

def gnu_add_configure_make_install(
        name,
        source_directory,
        autoreconf_args = None,
        configure_args = [],
        make_args = [],
        build_artifact_globs = None,
        deps = [],
        install_path = None):
    """
    Add an autotools project to the build

    Args:
        name: The name of the project
        source_directory: The directory of the project
        autoreconf_args: The arguments to pass to the autoreconf script
        configure_args: The arguments to pass to the configure script
        make_args: The arguments to pass to the make command
        build_artifact_globs: The globs to match the build artifacts
        deps: The dependencies of the project
        install_path: The path to install the project
    """

    build_dir = "build/{}".format(name)
    prepare_rule_name = "{}_prepare".format(name)
    autoreconf_rule_name = "{}_autoreconf".format(name)
    configure_rule_name = "{}_configure".format(name)
    build_rule_name = "{}_build".format(name)
    install_rule_name = "{}_install".format(name)
    workspace = info.get_absolute_path_to_workspace()
    install_path = "{}/build/install".format(workspace) if install_path == None else install_path
    prefix_arg = "--prefix={}".format(install_path)
    num_cpus = info.get_cpu_count()

    run_add_exec(
        prepare_rule_name,
        command = "mkdir",
        args = ["-p", build_dir],
    )

    autoreconf_deps = [prepare_rule_name]
    if autoreconf_args:
        run_add_exec(
            autoreconf_rule_name,
            deps = [prepare_rule_name] + deps,
            inputs = ["+{}/configure.ac".format(source_directory)],
            command = "autoreconf",
            args = autoreconf_args,
            working_directory = source_directory,
            help = "autoreconf {}".format(name),
        )
        autoreconf_deps = [autoreconf_rule_name]

    run_add_exec(
        configure_rule_name,
        deps = autoreconf_deps + deps,
        inputs = ["+{}/configure".format(source_directory)],
        command = "../../{}/configure".format(source_directory),
        args = [prefix_arg] + configure_args,
        working_directory = build_dir,
        help = "Configure {}".format(name),
    )

    run_add_exec(
        build_rule_name,
        deps = [configure_rule_name],
        inputs = [
            "+{}/Makefile".format(build_dir),
            "+{}/**".format(source_directory),
            "-{}/.git/**".format(source_directory),
        ],
        command = "make",
        args = ["-j{}".format(num_cpus)] + make_args,
        working_directory = build_dir,
        help = "Build {}".format(name),
    )

    run_add_exec(
        install_rule_name,
        deps = [build_rule_name],
        inputs = build_artifact_globs,
        command = "make",
        args = ["install"],
        working_directory = build_dir,
        help = "Install {}".format(name),
    )

    run_add_target(name, deps = [install_rule_name])


def gnu_add_repo(
        name,
        url,
        rev,
        autoreconf_args = None,
        configure_args = [],
        make_args = [],
        checkout_submodules = False,
        deps = [],
        install_path = None):
    """
    Add an autotools project from a repository

    Args:
        name: The name of the project
        url: The URL of the repository
        rev: The revision of the repository
        autoreconf_args: The arguments to pass to the autoreconf script
        configure_args: The arguments to pass to the configure script
        make_args: The arguments to pass to the make
        checkout_submodules: Whether to checkout submodules
        deps: The dependencies of the project
        install_path: The path to install the project
    """

    checkout_rule = "{}_source".format(name)
    checkout_add_repo(
        checkout_rule,
        url = url,
        rev = rev,
        clone = "Blobless",
    )

    submodule_rule = "{}_submodules".format(name)
    submodule_deps = []
    if checkout_submodules:
        run_add_exec(
            "{}_submodules".format(name),
            command = "git",
            args = ["submodule", "update", "--init", "--recursive"],
            working_directory = name,
        )
        submodule_deps = [submodule_rule]

    gnu_add_configure_make_install(
        name,
        source_directory = checkout_rule,
        autoreconf_args = autoreconf_args,
        configure_args = configure_args,
        make_args = make_args,
        deps = deps + submodule_deps,
        install_path = install_path,
    )
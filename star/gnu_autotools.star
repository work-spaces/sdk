"""
Build an autotools project

"""

load(
    "checkout.star",
    "checkout_add_archive",
    "checkout_add_platform_archive",
    "checkout_add_repo",
    "checkout_update_env",
)
load("run.star", "run_add_exec", "run_add_target")
load(
    "//@packages/star/github.com/packages.star",
    github_packages = "packages",
)

def gnu_add_configure_make_install(
        name,
        source_directory,
        autoreconf_args = None,
        configure_args = [],
        make_args = [],
        build_artifact_globs = [],
        deps = []):
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
    """

    build_dir = "build/{}".format(name)
    prepare_rule_name = "{}_prepare".format(name)
    autoreconf_rule_name = "{}_autoreconf".format(name)
    configure_rule_name = "{}_configure".format(name)
    build_rule_name = "{}_build".format(name)
    install_rule_name = "{}_install".format(name)
    workspace = info.get_absolute_path_to_workspace()
    install_path = "{}/build/install".format(workspace)
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

def gnu_add_source_archive(
        name,
        url,
        sha256,
        source_directory,
        autoreconf_args = None,
        configure_args = [],
        make_args = [],
        build_artifact_globs = [],
        deps = []):
    """
    Add an autotools project from an archive

    Args:
        name: The name of the project
        url: The URL of the archive
        sha256: The SHA256 of the archive
        source_directory: The directory of the project
        autoreconf_args: The arguments to pass to the autoreconf script
        configure_args: The arguments to pass to the configure script
        make_args: The arguments to pass to the make
        build_artifact_globs: The globs to match the build artifacts
        deps: The dependencies of the project
    """

    checkout_add_archive(
        name,
        url = url,
        sha256 = sha256,
    )

    gnu_add_configure_make_install(
        name,
        source_directory,
        autoreconf_args = autoreconf_args,
        configure_args = configure_args,
        make_args = make_args,
        deps = deps,
        build_artifact_globs = build_artifact_globs,
    )

def gnu_add_repo(
        name,
        url,
        rev,
        autoreconf_args = None,
        configure_args = [],
        make_args = [],
        checkout_submodules = False,
        deps = []):
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
    """
    checkout_add_repo(
        name,
        url = url,
        rev = rev,
        clone = "Shallow",
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
        source_directory = name,
        autoreconf_args = autoreconf_args,
        configure_args = configure_args,
        make_args = make_args,
        deps = deps + submodule_deps,
    )

def gnu_add_autotools_from_source():
    """
    Add the autotools from source
    """

    autoconf_version = "2.72"
    autoconf_sha256 = "ba885c1319578d6c94d46e9b0dceb4014caafe2490e437a0dbca3f270a223f5a"
    automake_version = "1.17"
    automake_sha256 = "8920c1fc411e13b90bf704ef9db6f29d540e76d232cb3b2c9f4dc4cc599bd990"
    libtool_version = "2.5.4"
    libtool_sha256 = "f81f5860666b0bc7d84baddefa60d1cb9fa6fceb2398cc3baca6afaa60266675"

    workspace = info.get_absolute_path_to_workspace()
    install_path = "{}/build/install/autotools".format(workspace)
    prefix_arg = "--prefix={}".format(install_path)

    checkout_add_platform_archive(
        "m4-1",
        platforms = github_packages["xpack-dev-tools"]["m4-xpack"]["v1.4.19-3"],
    )

    checkout_add_platform_archive(
        "spaces0",
        platforms = github_packages["work-spaces"]["spaces"]["v0.10.4"],
    )

    gnu_add_source_archive(
        "autoconf",
        url = "https://ftp.gnu.org/gnu/autoconf/autoconf-{}.tar.xz".format(autoconf_version),
        sha256 = autoconf_sha256,
        source_directory = "autoconf-{}".format(autoconf_version),
        configure_args = [prefix_arg],
    )

    gnu_add_source_archive(
        "automake",
        url = "https://ftp.gnu.org/gnu/automake/automake-{}.tar.xz".format(automake_version),
        sha256 = automake_sha256,
        source_directory = "automake-{}".format(automake_version),
        deps = ["autoconf_install"],
        configure_args = [prefix_arg],
    )

    gnu_add_source_archive(
        "libtool",
        url = "https://ftp.gnu.org/gnu/libtool/libtool-{}.tar.xz".format(libtool_version),
        sha256 = libtool_sha256,
        source_directory = "libtool-{}".format(libtool_version),
        deps = ["autoconf_install"],
        configure_args = [prefix_arg],
    )

    checkout_update_env(
        "gnu_autotools_update_build_env",
        paths = ["{}/bin".format(install_path)],
    )
    run_add_target("gnu_autotools_from_source", deps = ["autoconf_install", "automake_install", "libtool_install"])

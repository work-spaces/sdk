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
    "capsule.star",
    "capsule_add_checkout_and_run",
    "capsule_checkout_define_dependency",
)
load(
    "//@packages/star/github.com/packages.star",
    github_packages = "packages",
)
load("//@sources/star/ftp.gnu.org/sources.star", gnu_sources = "sources")

def gnu_add_configure_make_install(
        name,
        source_directory,
        autoreconf_args = None,
        configure_args = [],
        make_args = [],
        build_artifact_globs = [],
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

def gnu_add_configure_make_install_from_source(
        name,
        owner,
        repo,
        version,
        autoreconf_args = None,
        configure_args = [],
        make_args = [],
        build_artifact_globs = [],
        deps = [],
        install_path = None):
    """
    Add an autotools project from an archive

    Args:
        name: The name of the project
        owner: The owner of the repository
        repo: The repository name
        version: The version of the repository
        autoreconf_args: The arguments to pass to the autoreconf script
        configure_args: The arguments to pass to the configure script
        make_args: The arguments to pass to the make
        build_artifact_globs: The globs to match the build artifacts
        deps: The dependencies of the project
        install_path: The path to install the project
    """

    checkout_archive_rule = "{}_checkout_archive".format(name)
    source_archive = gnu_sources[owner][repo][version]

    checkout_add_archive(
        checkout_archive_rule,
        url = source_archive["url"],
        sha256 = source_archive["sha256"],
    )

    gnu_add_configure_make_install(
        name,
        source_directory = "{}-{}".format(repo, version),
        autoreconf_args = autoreconf_args,
        configure_args = configure_args,
        make_args = make_args,
        deps = deps,
        build_artifact_globs = build_artifact_globs,
        install_path = install_path,
    )

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
    checkout_add_repo(
        name,
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
        source_directory = name,
        autoreconf_args = autoreconf_args,
        configure_args = configure_args,
        make_args = make_args,
        deps = deps + submodule_deps,
        install_path = install_path,
    )

def gnu_add_autotools_from_source(
        name,
        autoconf_version,
        automake_version,
        libtool_version,
        install_path = None):
    """
    Add the autotools from source

    Args:
        name: The name of the add autotools ruls
        autoconf_version: The version of autoconf
        automake_version: The version of automake
        libtool_version: The version of libtool
        install_path: The path to install the autotools
    """

    autoconf_rule = "{}_autoconf".format(name)
    autoconf_install_rule = "{}_install".format(autoconf_rule)
    automake_rule = "{}_automake".format(name)
    libtool_rule = "{}_libtool".format(name)
    update_env_rule = "{}_update_env".format(name)

    workspace = info.get_absolute_path_to_workspace()
    effective_install_path = "{}/build/install/autotools".format(workspace) if install_path == None else install_path

    checkout_add_platform_archive(
        "m4-1",
        platforms = github_packages["xpack-dev-tools"]["m4-xpack"]["v1.4.19-3"],
    )

    gnu_add_configure_make_install_from_source(
        autoconf_rule,
        "autoconf",
        "autoconf",
        autoconf_version,
        install_path = effective_install_path,
    )

    gnu_add_configure_make_install_from_source(
        automake_rule,
        "automake",
        "automake",
        automake_version,
        deps = [autoconf_install_rule],
        install_path = effective_install_path,
    )

    gnu_add_configure_make_install_from_source(
        libtool_rule,
        "libtool",
        "libtool",
        libtool_version,
        deps = [autoconf_install_rule],
        install_path = effective_install_path,
    )

    checkout_update_env(
        update_env_rule,
        paths = ["{}/bin".format(effective_install_path)],
    )

    run_add_target(name, deps = [
        autoconf_install_rule,
        "{}_install".format(automake_rule),
        "{}_install".format(libtool_rule),
    ])

def gnu_capsule(repo, owner = None, domain = "ftp.gnu.org"):
    """
    Get the capsule descriptor for the GNU source

    Args:
        repo: The repository name
        owner: The owner of the repository
        domain: The domain of the repository (Default is ftp.gnu.org)
    """
    effective_owner = owner if owner else repo
    return capsule(domain, effective_owner, repo)

def gnu_capsule_define_dependency(
        name,
        capsule,
        version):
    """
    Define the dependency for the capsule

    Args:
        name: The rule name
        capsule: return value of capsule()
        version: The version of the repository
    """
    capsule_checkout_define_dependency(
        "{}_info".format(capsule_name),
        capsule = capsule,
        version = version,
    )

def gnu_capsule_add_checkout_and_run(
        name,
        capsule,
        version,
        oras_url = None,
        gh_deploy_repo = None,
        suffix = "tar.gz",
        configure_args = []):
    """
    Add the checkout and run if the install path does not exist

    Args:
        name: The name of the capsule
        capsule: The capsule descriptor
        version: The version of the repository
        oras_url: The ORAS URL to deploy the capsule
        gh_deploy_repo: The repository to deploy the capsule to
        suffix: The suffix of the archive file (tar.gz, tar.xz, tar.bz2, zip)
        configure_args: The arguments to pass to the configure script
    """

    def build_function(name, install_path, args):
        gnu_add_configure_make_install_from_source(
            name,
            owner = args["owner"],
            repo = args["repo"],
            version = args["version"],
            install_path = install_path,
            configure_args = args["configure_args"],
        )

    capsule_add_checkout_and_run(
        name,
        capsule = capsule,
        version = version,
        oras_url = oras_url,
        gh_deploy_repo = gh_deploy_repo,
        suffix = suffix,
        build_function = build_function,
        build_args = {
            "owner": capsule["owner"],
            "repo": capsule["repo"],
            "version": version,
            "configure_args": configure_args,
        },
    )

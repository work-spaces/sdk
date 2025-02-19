"""
Update RPATHs for loading shared libraries
"""

load("run.star", "run_add_exec", "run_add_target")

def rpath_update_macos_install_dir(name, install_path, deps):
    """
    Update the rpaths of the binaries on macOS.

    Args:
        name: The name of the rule
        install_path: The path to the install directory
        deps: The dependencies of the rule
    """

    BIN_RULE_NAME = "{}_bin".format(name)
    LIB_RULE_NAME = "{}_lib".format(name)

    run_add_exec(
        BIN_RULE_NAME,
        deps = deps,
        command = "@star/sdk/script/update-rpath-macos.star",
        args = [
            "--binary-path={}/bin".format(install_path),
            "--old-path={}".format(install_path),
            "--new-path=@executable_path/..",
        ],
        help = "Update MacOS rpath entries in build/install/bin",
    )

    run_add_exec(
        LIB_RULE_NAME,
        deps = deps,
        command = "@star/sdk/script/update-rpath-macos.star",
        args = [
            "--binary-path={}/lib".format(install_path),
            "--old-path={}/lib".format(install_path),
            "--new-path=@loader_path",
        ],
        help = "Update MacOS rpath entries in build/install/lib",
    )

    run_add_target(name, deps = [BIN_RULE_NAME, LIB_RULE_NAME])
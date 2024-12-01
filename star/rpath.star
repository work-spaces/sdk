"""
Update RPATHs for loading shared libraries
"""

load("run.star", "run_add_exec")

def rpath_update_macos_install_dir(rule_name, install_path, deps):
    """
    Update the rpaths of the binaries on macOS.

    Args:
        rule_name: The name of the rule
        install_path: The path to the install directory
        deps: The dependencies of the rule
    """

    bin_rule_name = "{}_bin".format(rule_name)
    lib_rule_name = "{}_lib".format(rule_name)

    run_add_exec(
        bin_rule_name,
        deps = deps,
        command = "spaces-starlark-sdk/script/update-rpath-macos.star",
        args = [
            "--binary-path={}/bin".format(install_path),
            "--old-path={}".format(install_path),
            "--new-path=@executable_path/..",
        ],
        help = "Update MacOS rpath entries in build/install/bin",
    )

    run_add_exec(
        lib_rule_name,
        deps = deps,
        command = "spaces-starlark-sdk/script/update-rpath-macos.star",
        args = [
            "--binary-path={}/lib".format(install_path),
            "--old-path={}/lib".format(install_path),
            "--new-path=@loader_path",
        ],
        help = "Update MacOS rpath entries in build/install/lib",
    )
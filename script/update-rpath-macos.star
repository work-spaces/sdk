#!/usr/bin/env spaces

"""Update the rpaths in an install directory"""

def _update_rpaths(files, install_path, new_base_path):
    """
    Update the rpaths in the files to use the new_base_path

    Args:
        files (list): List of files to update
        install_path (str): The path to search for in the rpaths
        new_base_path (str): The new path to replace install_path with
    """

    if info.is_platform_macos() == False:
        return

    for file in files:
        if file.endswith(".a") or file.endswith(".o"):
            continue

        otool_result = process.exec(
            exec = {
                "command": "otool",
                "args": ["-L", file],
            }
        )
        if otool_result["status"] != 0:
            script.print("Skipping non-binary file: {}".format(file))
            continue
            
        lines = otool_result["stdout"].splitlines()
        for line in lines:
            line = line.strip()
            if line.startswith(install_path):
                change_old = line.split(" ")[0]
                change_new = change_old.replace(install_path, new_base_path)
                install_name_result = process.exec(
                    exec = {
                        "command": "install_name_tool",
                        "args": ["-change", change_old, change_new, file],
                    }
                )
                if install_name_result["status"] != 0:
                    script.print("Warning running install_name_tool for {}".format(file))
                    script.print(install_name_result["stderr"])
                    continue
                script.print("{}: {} -> {}".format(file, change_old, change_new))

args = script.get_args()
binary_path = args["named"]["--binary-path"]
old_path = args["named"]["--old-path"]
new_path = args["named"]["--new-path"]

files = fs.read_directory(binary_path)

_update_rpaths(files, old_path, new_path)
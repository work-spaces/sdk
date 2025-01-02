#!/usr/bin/env spaces

"""Update the rpaths in an install directory"""

def _update_rpaths(binary_path, install_path, new_base_path):
    """
    Update the rpaths in the files to use the new_base_path

    Args:
        binary_path (str): The path to the binaries to update
        install_path (str): The path to search for in the rpaths
        new_base_path (str): The new path to replace install_path with
    """

    if info.is_platform_macos() == False:
        return

    if not fs.exists(binary_path):
        return

    files = fs.read_directory(binary_path)

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

        file_name = file.split("/")[-1]
        
        id_result = process.exec(
            exec = {
                "command": "install_name_tool",
                "args": ["-id", "@rpath/{}".format(file_name), file],
            }
        )

        if id_result["status"] != 0:
            script.print("Warning running install_name_tool for {}".format(file))
            script.print(id_result["stderr"])
            continue

        process.exec(
            exec = {
                "command": "install_name_tool",
                "args": ["-delete_rpath", "{}/lib".format(install_path), file],
            }
        )


        process.exec(
            exec = {
                "command": "install_name_tool",
                "args": ["-add_rpath", "@loader_path", file],
            }
        )

        process.exec(
            exec = {
                "command": "install_name_tool",
                "args": ["-add_rpath", "@loader_path/../lib", file],
            }
        )

args = script.get_args()
binary_path = args["named"]["--binary-path"]
old_path = args["named"]["--old-path"]
new_path = args["named"]["--new-path"]

_update_rpaths(binary_path, old_path, new_path)
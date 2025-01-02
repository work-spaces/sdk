#!/usr/bin/env spaces

"""Update the rpaths in an install directory"""

def _update_shebang(input_file, new_shebang):
    """
    Update the shebang line in the input file

    Args:
        input_file (str): The path to the file to update
        new_shebang (str): The new shebang line
    """

    if not fs.is_file(input_file):
        return

    contents = fs.read_file_to_string(input_file)

    for line in contents.splitlines():
        if line.startswith("#!"):
            new_contents = contents.replace(line, new_shebang)
            fs.write_string_to_file(
                path = input_file,
                content = new_contents,
            )
            return

args = script.get_args()
input_file = args["named"]["--input-file"]
new_shebang = args["named"]["--new-shebang"]

_update_shebang(input_file, new_shebang)

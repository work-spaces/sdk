"""
Update the she-bang line for a file
"""

load("run.star", "run_add_exec")

def shebang_add_update(name, input_file, new_shebang, deps):
    """
    Update the she-bang for a file

    Args:
        name: The name of the rule
        input_file: The path to the file to update
        new_shebang: The new she-bang line
        deps: The dependencies of the rule
    """

    run_add_exec(
        name,
        deps = deps,
        command = "@star/sdk/script/update-shebang.star",
        args = [
            "--input-file={}".format(input_file),
            "--new-shebang={}".format(new_shebang),
        ],
        help = "Update the she-bang line for a shell script",
    )
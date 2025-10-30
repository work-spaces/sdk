"""
Merge compile commands that are defined during checkout.
"""

load("checkout.star", "checkout_get_compile_commands_spaces_name")
load("run.star", "run_add_exec")
load("std/fs.star", "fs_exists", "fs_is_file", "fs_read_json")

def compile_commands_merge(name, output = None):
    """
    Merges compile commands from different directories into a single file.

    This can be used with multiple calls to checkout_add_compile_commands_dir().

    Args:
        name (str): The name of the rule.
        output (str, optional): The output file path. Defaults to "build/compile_commands.json".
    """

    CONFIG_FILE_NAME = checkout_get_compile_commands_spaces_name()

    if fs_exists(CONFIG_FILE_NAME) and fs_is_file(CONFIG_FILE_NAME):
        EFFECTIVE_OUTPUT = output if output != None else "build/compile_commands.json"
        CONFIG = fs_read_json(CONFIG_FILE_NAME)
        INPUTS = ["+//{}/compile_commands.json".format(path) for path in CONFIG.keys()]

        run_add_exec(
            name,
            command = "@star/sdk/script/merge-compile-commands.star",
            args = [
                "--manifest={}".format(CONFIG_FILE_NAME),
                "--outputs={}".format(EFFECTIVE_OUTPUT),
            ],
            deps = CONFIG.values(),
            inputs = INPUTS,
            help = """
Merges the compile_commands.json file in these directories: {}
""".format(", ".join(CONFIG.keys())),
        )

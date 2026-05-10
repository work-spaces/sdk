#!/usr/bin/env spaces

load(
    "//@star/sdk/star/script.star",
    "script_get_args",
    "script_print",
)
load(
    "//@star/sdk/star/std/fs.star",
    "fs_read_json",
    "fs_read_text",
    "fs_write_text",
)
load("//@star/sdk/star/std/json.star", "json_dumps")
load("//@star/sdk/star/std/sys.star", "sys_exit")

def main():
    ARGUMENTS = script_get_args()
    NAMED_ARGUMENTS = ARGUMENTS["named"]

    COMPILE_COMMANDS_JSON = "compile_commands.json"

    if "--manifest" in NAMED_ARGUMENTS:
        MANIFEST = NAMED_ARGUMENTS["--manifest"]

        compile_command_object = fs_read_json(MANIFEST)
        all_commands = []
        for compile_command_dir in compile_command_object.keys():
            compile_command_array = fs_read_json("{}/{}".format(compile_command_dir, COMPILE_COMMANDS_JSON))
            for item in compile_command_array:
                all_commands.append(item)

        output = NAMED_ARGUMENTS.get("--output", "build/{}".format(COMPILE_COMMANDS_JSON))
        output_string = json_dumps(all_commands, is_pretty = True)
        fs_write_text(output, output_string)
        return 0

    else:
        script_print("Missing required argument: --manifest")
        return 1

exit_code = main()
sys_exit(exit_code)

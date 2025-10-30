#!/usr/bin/env spaces

load(
    "//@star/sdk/star/script.star",
    "script_get_args",
    "script_print",
    "script_set_exit_code",
)
load(
    "//@star/sdk/star/std/fs.star",
    "fs_read_json",
    "fs_read_text",
    "fs_write_text",
)
load("//@star/sdk/star/std/json.star", "json_dumps")

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

else:
    script_print("Missing required argument: --manifest")
    script_set_exit_code(1)

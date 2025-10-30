#!/usr/bin/env spaces

"""
Periodically scan a log file for a string. Exit with code 1 if the string is not found within the timeout.
"""

load("//@star/sdk/star/info.star", "info_parse_log_file")
load(
    "//@star/sdk/star/script.star",
    "script_get_args",
    "script_print",
    "script_set_exit_code",
)
load("//@star/sdk/star/std/time.star", "time_now", "time_sleep")

ARGUMENTS = script_get_args()

NAMED_ARGUMENTS = ARGUMENTS["named"]
SAMPLING_PERIOD = float(NAMED_ARGUMENTS.get("--sampling-period", 1.0))
TIMEOUT = float(NAMED_ARGUMENTS.get("--timeout", 10.0))
EXPECTED = NAMED_ARGUMENTS.get("--expected", "")

if "--path" in NAMED_ARGUMENTS and "--expected" in NAMED_ARGUMENTS:
    PATH = NAMED_ARGUMENTS["--path"]
    EXPECTED = NAMED_ARGUMENTS["--expected"]
    START = time_now()
    LOOP_COUNT = int(TIMEOUT / SAMPLING_PERIOD)

    is_found = False

    for _ in range(LOOP_COUNT):
        RESULT = info_parse_log_file(PATH)
        for lines in RESULT["lines"]:
            if EXPECTED in lines:
                is_found = True
                break

        if is_found:
            break

        time_sleep(SAMPLING_PERIOD)

    if not is_found:
        script_print("Error: Did not find `{}` in {} after {} seconds".format(EXPECTED, PATH, TIMEOUT))
        script_set_exit_code(1)
    else:
        script_print("Success: Found `{}` in {} after {} seconds".format(EXPECTED, PATH, time_now() - START))

else:
    script_print("Usage: scan-log-file.star --path=<path> --expected=<expected> [--sampling-period=<sampling-period>] [--timeout=<timeout>]")
    script_set_exit_code(1)

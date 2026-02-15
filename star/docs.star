"""
Starlark functions to copying content in to the workspace @docs
content folder.
"""

load(
    "checkout.star",
    "checkout_add_asset",
    "checkout_add_hard_link_asset",
)
load("shell.star", "cp", "mkdir")
load("std/fs.star", "fs_exists")

def docs_add_hard_link_asset(
        name,
        source,
        deps = [],
        type = None,
        platforms = None,
        visibility = None):
    """
    Adds content to the workspace @docs content folder using a hard link.

    The `source` is hardlinked to @docs/content/docs/<name> in the workspace.

    The rule is only created if the @docs/content/docs folder exists.
    """

    if fs_exists("@docs/content/docs"):
        checkout_add_hard_link_asset(
            name = name,
            source = source,
            destination = "@docs/content/docs/" + name + ".md",
            deps = deps,
            type = type,
            platforms = platforms,
            visibility = visibility,
        )

def docs_add_asset(
        name,
        content,
        deps = [],
        type = None,
        platforms = None,
        visibility = None):
    """
    Adds string content to the workspace @docs content folder.

    The `content` is a string that is written to @docs/content/docs/<name>.md
    in the workspace.

    The rule is only created if the @docs/content/docs folder exists.
    """

    if fs_exists("@docs/content/docs"):
        checkout_add_asset(
            name = name,
            content = content,
            destination = "@docs/content/docs/" + name + ".md",
            deps = deps,
            type = type,
            platforms = platforms,
            visibility = visibility,
        )

def docs_cp(
        name,
        source,
        destination,
        options = [],
        deps = [],
        type = None,
        inputs = None,
        working_directory = None):
    """
    Adds content to the workspace @docs content folder using `cp`.

    The `source` is copied to @docs/content/docs/<destination> in the workspace.

    The rule is only created if the @docs/content/docs folder exists.

    Args:
        name: The name of the rule.
        source: The source file or directory to copy.
        destination: The destination folder in the @docs/content/docs folder.
        options: Additional options for the `cp` command.
        deps: Dependencies for the rule.
        type: The type of the rule.
        inputs: Rules inputs to determine if run can be skipped.
        working_directory: The working directory for the `cp` command.
    """

    if fs_exists("@docs/content/docs"):
        EFFECTIVE_OPTIONS = options if options else ["-rf"]
        MKDIR_RULE = "{}_mkdir".format(name)
        DESTINATION_PATH = "@docs/content/docs/" + destination
        mkdir(
            MKDIR_RULE,
            path = DESTINATION_PATH,
            options = ["-p"],
            deps = deps,
        )

        cp(
            name = name,
            source = source,
            destination = DESTINATION_PATH,
            options = EFFECTIVE_OPTIONS,
            inputs = inputs,
            working_directory = working_directory,
            deps = [MKDIR_RULE],
            type = type,
        )

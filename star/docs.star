"""
Starlark functions to copying content in to the workspace @docs
content folder.
"""

load("checkout.star", 
    "checkout_add_hard_link_asset",
    "checkout_add_soft_link_asset",
    "checkout_add_asset")

load("std/fs.star", "fs_exists")

def docs_add_hard_link_asset(
    name,
    source,
    deps = [],
    type = None,
    platforms = None):
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
        )

def docs_add_asset(
    name,
    content,
    deps = [],
    type = None,
    platforms = None):
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
        )
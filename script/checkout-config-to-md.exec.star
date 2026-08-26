#!/usr/bin/env spaces
"""
Converts the checkout config registry to a markdown file.
"""

load("//@star/prelude/exec/args.star", "args_opt", "args_parse", "args_parser")
load("//@star/prelude/exec/fs.star", "fs_read_text", "fs_write_text")
load("//@star/prelude/exec/io.star", "io_print")
load("//@star/prelude/exec/json.star", "json_decode")
load("//@star/prelude/exec/string.star", "string_lower", "string_replace")
load("//@star/prelude/exec/sys.star", "sys_exit")

_DEFAULT_OUTPUT_PATH = "checkout-config.md"

_HEADER = """# Checkout Configuration

This document lists the checkout store values that are available in the workspace.
These values can be used to customize how the workspace is checked out.
The values can be set when running `spaces co ...` or `spaces checkout-repo ...`

For example:

```sh"
spaces co ... --store=<key>=<value>
spaces checkout-repo ... --store=<key>=<value>
spaces sync ... --store=<key>=<value>
```

Use `spaces sync --help` or `spaces co --help` for more details.

"""

def _anchor_from_name(name: str) -> str:
    normalized = string_lower(name)
    slug = string_lower(name)
    slug = string_replace(slug, " ", "-")
    slug = string_replace(slug, "--", "-")

    if slug == "":
        return "entry"
    return slug

def _md_escape_inline(value) -> str:
    text = str(value)
    text = string_replace(text, "|", "\\|")
    text = string_replace(text, "\n", " ")
    return text

def _render_markdown(registry: dict, values: dict) -> str:
    lines = []

    lines.append(_HEADER)
    lines.append("# Quick Look")
    lines.append("")
    lines.append("| Name | Type |")
    lines.append("| --- | --- |")

    for name, entry in registry.items():
        entry_value = _md_escape_inline(values.get(name, "None"))
        lines.append("| [{}](#{}) | {} |".format(_md_escape_inline(name), _anchor_from_name(name), entry_value))

    lines.append("")
    lines.append("# Details")
    lines.append("")

    for name, entry in registry.items():
        entry_type = str(entry.get("type", "unknown"))
        value = values.get(name, "None")
        help_text = entry.get("help")
        if help_text == None:
            help_text = ""

        lines.append("## {}".format(name))
        lines.append("")
        lines.append("**value**: {}\n".format(_md_escape_inline(value)))
        lines.append("**type**: {}\n".format(_md_escape_inline(entry_type)))
        lines.append("**help**: {}\n".format(_md_escape_inline(help_text)))

        if entry_type == "enum":
            enum_values = entry.get("values", [])
            lines.append("")
            lines.append("**values**")
            lines.append("")

            if len(enum_values) == 0:
                lines.append("- (none)")
            else:
                for enum_entry in enum_values:
                    enum_value = enum_entry.get("value")
                    enum_help = enum_entry.get("help")
                    if enum_value == None:
                        continue

                    value_text = _md_escape_inline(enum_value)
                    if enum_help == None or enum_help == "":
                        lines.append("- {}".format(value_text))
                    else:
                        lines.append("- {}: {}".format(value_text, _md_escape_inline(enum_help)))

        lines.append("")

    return "\n".join(lines)

def main() -> int:
    parser = args_parser(
        name = "checkout-config-to-md.exec.star",
        description = "Convert checkout config registry entries from store.spaces.json to markdown docs.",
        options = [
            args_opt("--input", help = "Path to the checkout config registry"),
            args_opt("--output", default = _DEFAULT_OUTPUT_PATH, help = "Output markdown file path."),
        ],
    )
    parsed = args_parse(parser)

    input = parsed.get("input", "<required>")
    output = parsed.get("output", _DEFAULT_OUTPUT_PATH)

    input_dict = json_decode(fs_read_text(input))
    registry = input_dict.get("registry", {})
    values = input_dict.get("values", {})
    markdown = _render_markdown(registry, values)

    fs_write_text(output, markdown)
    io_print("Wrote markdown to {}".format(output))

    return 0

sys_exit(main())

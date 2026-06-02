"""
Re-exports `text` utilities from `//@star/prelude/exec/text.star`.
"""

load(
    "//@star/prelude/exec/text.star",
    "text_scan_file",  # @unused
    "text_scan_lines",  # @unused
    "text_line_count",  # @unused
    "text_read_line_range",  # @unused
    "text_head",  # @unused
    "text_tail",  # @unused
    "text_grep",  # @unused
    "text_dedent",  # @unused
    "text_scan_windows",  # @unused
    "text_scan_windows_file",  # @unused
    "text_regex_scan",  # @unused
    "text_regex_scan_file",  # @unused
    "text_regex_scan_tagged",  # @unused
    "text_regex_scan_tagged_file",  # @unused
    "text_diagnostic",  # @unused
    "text_match_to_diagnostic",  # @unused
    "text_dedup_diagnostics",  # @unused
    "text_render_diagnostics",  # @unused
)

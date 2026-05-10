#!/usr/bin/env spaces
"""
Parse a known tool's output into diagnostics using a TOML rule file.

This script converts captured tool output (from cargo, cmake, ninja, clang, etc.)
into structured diagnostics, enriched with actionable hints, rendered in various formats.

The script is invoked once per known toolchain output and requires a TOML rule file
describing that toolchain's error/warning patterns and common-cause hints.
"""

load("//@star/sdk/star/std/args.star", "args_flag", "args_opt", "args_parse", "args_parser")
load("//@star/sdk/star/std/fs.star", "fs_exists", "fs_read_text", "fs_write_text")
load("//@star/sdk/star/std/log.star", "log_debug", "log_error", "log_info")
load("//@star/sdk/star/std/string.star", "string_regex_match", "string_replace")
load("//@star/sdk/star/std/sys.star", "sys_exit")
load(
    "//@star/sdk/star/std/text.star",
    "text_dedup_diagnostics",
    "text_diagnostic",
    "text_match_to_diagnostic",
    "text_regex_scan_tagged_file",
    "text_render_diagnostics",
)
load("//@star/sdk/star/std/tmp.star", "tmp_cleanup_all", "tmp_file")
load("//@star/sdk/star/std/toml.star", "toml_decode")

# ============================================================================
# CLI Specification
# ============================================================================

def make_parser():
    """Create the argument parser specification."""
    return args_parser(
        name = "output-parser.exec.star",
        description = "Parse tool output into diagnostics using TOML rules",
        options = [
            args_opt("--rules", help = "Path to TOML rules file (required)"),
            args_opt("--input", help = "Path to input log file, or '-' for stdin (required)"),
            args_opt(
                "--format",
                default = "human",
                choices = ["human", "github", "json", "sarif"],
                help = "Output format (default: human)",
            ),
            args_opt("--output", help = "Optional file to write rendered output to"),
            args_opt(
                "--fail-on",
                default = "error",
                choices = ["error", "warning", "never"],
                help = "Exit with non-zero when diagnostics meet threshold (default: error)",
            ),
            args_opt("--max-matches", type = "int", default = 0, help = "Maximum matches to return (0 = unlimited)"),
            args_flag("--no-dedup", help = "Disable diagnostic deduplication"),
            args_flag("--no-strip-ansi", help = "Disable ANSI escape stripping"),
        ],
    )

# ============================================================================
# Configuration Loading and Validation
# ============================================================================

def load_config(path):
    """
    Load and decode the TOML configuration file.

    Returns a dict with keys: parser, rule, cause
    """
    assert_on(fs_exists(path), "Rules file not found: " + path)

    content = fs_read_text(path)
    cfg = toml_decode(content)

    # Normalize structure
    parser_cfg = cfg.get("parser", {})
    rules = cfg.get("rule", [])
    causes = cfg.get("cause", [])

    return {
        "parser": parser_cfg,
        "rule": rules,
        "cause": causes,
    }

def validate_rules(rules):
    """
    Validate rule structure and cross-references.

    Raises fail() on validation errors with helpful messages.
    """
    if not rules:
        log_info("No rules defined in configuration")
        return

    # Track tags for attach_to validation
    tags = {}

    for idx, rule in enumerate(rules):
        # Check required fields
        if "tag" not in rule or not rule["tag"]:
            fail("Rule at index %d: missing required field 'tag'" % idx)

        if "pattern" not in rule or not rule["pattern"]:
            fail("Rule at index %d: missing required field 'pattern'" % idx)

        tag = rule["tag"]

        # Check for duplicate tags
        if tag in tags:
            fail("Rule at index %d: duplicate tag '%s' (previously defined at index %d)" % (idx, tag, tags[tag]))
        tags[tag] = idx

        # Severity is required unless attach_to is set
        has_attach = "attach_to" in rule and rule["attach_to"]
        if not has_attach and ("severity" not in rule or not rule["severity"]):
            fail("Rule at index %d (tag '%s'): missing required field 'severity' (not needed if attach_to is set)" % (idx, tag))

        # Validate severity value
        if "severity" in rule and rule["severity"]:
            valid_severities = ["error", "warning", "info", "hint", "note"]
            if rule["severity"] not in valid_severities:
                fail("Rule at index %d (tag '%s'): invalid severity '%s', must be one of: %s" %
                     (idx, tag, rule["severity"], ", ".join(valid_severities)))

    # Second pass: validate attach_to references
    for idx, rule in enumerate(rules):
        if "attach_to" in rule and rule["attach_to"]:
            target_tag = rule["attach_to"]
            if target_tag not in tags:
                fail("Rule at index %d (tag '%s'): attach_to references unknown tag '%s'" %
                     (idx, rule["tag"], target_tag))

def validate_causes(causes):
    """
    Validate cause structure.

    Raises fail() on validation errors.
    """
    if not causes:
        return

    for idx, cause in enumerate(causes):
        # At least one selector required
        has_selector = any([
            "match_tag" in cause,
            "match_code" in cause,
            "match_message" in cause,
            "match_message_regex" in cause,
        ])

        if not has_selector:
            fail("Cause at index %d: at least one selector required (match_tag, match_code, match_message, match_message_regex)" % idx)

        # Hint is required
        if "hint" not in cause or not cause["hint"]:
            fail("Cause at index %d: missing required field 'hint'" % idx)

# ============================================================================
# Settings Resolution
# ============================================================================

def resolve_settings(args, cfg):
    """
    Resolve effective settings from CLI args and TOML config.

    CLI arguments always win over TOML config.
    Returns a dict with resolved settings.
    """
    parser_cfg = cfg.get("parser", {})

    # Format
    format_val = args.get("format", "human")
    if not format_val:
        format_val = parser_cfg.get("format", "human")

    # Fail-on threshold
    fail_on = args.get("fail_on", "error")
    if not fail_on:
        fail_on = parser_cfg.get("fail_on", "error")

    # Dedup (inverted flag logic)
    dedup = not args.get("no_dedup", False)
    if args.get("no_dedup", False):
        dedup = False
    else:
        dedup = parser_cfg.get("dedup", True)

    # Strip ANSI (inverted flag logic)
    strip_ansi = not args.get("no_strip_ansi", False)
    if args.get("no_strip_ansi", False):
        strip_ansi = False
    else:
        strip_ansi = parser_cfg.get("strip_ansi", True)

    # Default source
    source = parser_cfg.get("source", "")

    # Max matches
    max_matches = args.get("max_matches", 0)

    return {
        "format": format_val,
        "fail_on": fail_on,
        "dedup": dedup,
        "strip_ansi": strip_ansi,
        "source": source,
        "max_matches": max_matches,
    }

# ============================================================================
# Input Staging
# ============================================================================

def stage_input(input_path, strip_ansi):
    """
    Prepare the input file for scanning.

    - If input is '-', read from stdin and stage to temp file
    - If strip_ansi is enabled, strip ANSI escapes to a temp file
    - Otherwise, return input path as-is

    Returns the path to scan.
    """

    # Handle stdin
    if input_path == "-":
        log_debug("Reading from stdin")

        # Read stdin via script args - not directly available, so we need to use a different approach
        # For now, fail with helpful message
        fail("stdin input ('-') is not yet implemented - please use a file path")

    # Check file exists
    assert_on(fs_exists(input_path), "Input file not found: " + input_path)

    # If no ANSI stripping needed, return as-is
    if not strip_ansi:
        return input_path

    # Strip ANSI escapes to temp file
    log_debug("Stripping ANSI escapes from input")
    content = fs_read_text(input_path)

    # Simple ANSI escape pattern: ESC [ ... m
    # This is a simplified version; a full implementation would need proper regex
    stripped = strip_ansi_codes(content)

    temp_path = tmp_file(suffix = ".txt")
    fs_write_text(temp_path, stripped)

    return temp_path

def strip_ansi_codes(text):
    """
    Strip ANSI escape codes from text.

    Uses regex to remove common ANSI escape sequences including:
    - CSI sequences: ESC [ ... (letter)
    - Other ESC sequences
    """

    # Remove ANSI escape sequences using regex
    # Pattern matches: ESC [ followed by zero or more chars, ending with a letter
    return string_replace(text, r"\x1b\[[^a-zA-Z]*[a-zA-Z]", "", regex = True)

# ============================================================================
# Scanning
# ============================================================================

def scan_file(path, rules):
    """
    Scan the input file for pattern matches.

    Returns list of matches with: tag, line, column, match, named
    """

    # Build pattern list for text_regex_scan_tagged_file
    patterns = []
    for rule in rules:
        patterns.append({
            "tag": rule["tag"],
            "pattern": rule["pattern"],
        })

    if not patterns:
        log_info("No patterns to scan")
        return []

    log_debug("Scanning file with %d patterns" % len(patterns))
    matches = text_regex_scan_tagged_file(path, patterns)
    log_debug("Found %d matches" % len(matches))

    return matches

# ============================================================================
# Match to Diagnostic Conversion
# ============================================================================

def matches_to_diagnostics(matches, rules, default_source):
    """
    Convert matches to diagnostics, handling attach_to merging.

    Returns list of diagnostic dicts.
    """

    # Build rule lookup by tag
    rule_by_tag = {}
    for rule in rules:
        rule_by_tag[rule["tag"]] = rule

    diagnostics = []

    # Track most recent diagnostic by rule tag for attach_to merging
    last_diag_by_tag = {}

    for match in matches:
        tag = match["tag"]
        rule = rule_by_tag.get(tag)
        if not rule:
            log_error("Match has unknown tag: " + tag)
            continue

        named = match.get("named", {})

        # Check if this is an attach_to rule
        if "attach_to" in rule and rule["attach_to"]:
            target_tag = rule["attach_to"]
            target_diag = last_diag_by_tag.get(target_tag)

            if not target_diag:
                log_debug("attach_to target '%s' not found, skipping attachment" % target_tag)
                continue

            # Merge named captures into target diagnostic
            # Only merge location fields if not already set or if set to "unknown"
            if "file" in named:
                if "file" not in target_diag or not target_diag["file"] or target_diag["file"] == "unknown":
                    target_diag["file"] = named["file"]
            if "line" in named:
                if "line" not in target_diag or target_diag["line"] == None:
                    target_diag["line"] = int(named["line"])
            if "column" in named:
                if "column" not in target_diag or target_diag["column"] == None:
                    target_diag["column"] = int(named["column"])
            if "end_line" in named:
                if "end_line" not in target_diag or target_diag["end_line"] == None:
                    target_diag["end_line"] = int(named["end_line"])
            if "end_column" in named:
                if "end_column" not in target_diag or target_diag["end_column"] == None:
                    target_diag["end_column"] = int(named["end_column"])
            if "code" in named:
                if "code" not in target_diag or not target_diag["code"]:
                    target_diag["code"] = named["code"]

            # Store all named captures as metadata for cause matching
            if "_captures" not in target_diag:
                target_diag["_captures"] = {}
            target_diag["_captures"].update(named)
        else:
            # Create new diagnostic using text_match_to_diagnostic
            severity_val = rule.get("severity", "error")
            source_val = rule.get("source", default_source)

            # Message: use captured message or fall back to full match
            default_message = match.get("match", "")

            # Create diagnostic
            diag = text_match_to_diagnostic(
                match = match,
                severity = severity_val,
                default_message = default_message,
                default_file = "unknown",
                source = source_val if source_val else None,
            )

            # Store metadata for cause matching
            diag["_tag"] = tag
            diag["_captures"] = dict(named)

            diagnostics.append(diag)
            last_diag_by_tag[tag] = diag

    return diagnostics

# ============================================================================
# Cause Mapping
# ============================================================================

def apply_causes(diagnostics, causes):
    """
    Apply cause hints to diagnostics based on selectors.

    Modifies diagnostics in-place to add related notes.
    """
    if not causes:
        return diagnostics

    for diag in diagnostics:
        # Try each cause in order
        for cause in causes:
            match_result = match_cause(diag, cause)
            if match_result:
                # Use hint template directly (no expansion)
                hint_text = cause["hint"]

                # Create related diagnostic (note)
                note = text_diagnostic(
                    file = diag.get("file", ""),
                    severity = "note",
                    message = hint_text,
                    line = diag.get("line"),
                    column = diag.get("column"),
                )

                # Add URL if present
                if "url" in cause and cause["url"]:
                    url_text = cause["url"]
                    note["_url"] = url_text
                    note["message"] = note["message"] + " [" + url_text + "]"

                # Attach to diagnostic as related
                if "related" not in diag:
                    diag["related"] = []
                diag["related"].append(note)

                # First matching cause wins
                break

    return diagnostics

def match_cause(diag, cause):
    """
    Check if a cause matches a diagnostic based on selectors.

    All specified selectors must match.
    Returns True for simple match, or match dict for regex matches with captures.
    """

    # match_tag
    if "match_tag" in cause:
        if diag.get("_tag") != cause["match_tag"]:
            return False

    # match_code
    if "match_code" in cause:
        if diag.get("code") != cause["match_code"]:
            return False

    # match_message (substring)
    if "match_message" in cause:
        msg = diag.get("message", "")
        if cause["match_message"] not in msg:
            return False

    # match_message_regex
    regex_match_result = None
    if "match_message_regex" in cause:
        msg = diag.get("message", "")
        pattern = cause["match_message_regex"]

        # Use proper regex matching from string module
        regex_match_result = string_regex_match(pattern, msg)
        if not regex_match_result:
            return False

    # when_code filter
    if "when_code" in cause:
        if diag.get("code") != cause["when_code"]:
            return False

    # when_severity filter
    if "when_severity" in cause:
        if diag.get("severity") != cause["when_severity"]:
            return False

    # when_source filter
    if "when_source" in cause:
        if diag.get("source") != cause["when_source"]:
            return False

    # Return regex match result if available (for capture groups), else True
    return regex_match_result if regex_match_result else True

# ============================================================================
# Finalization
# ============================================================================

def finalize_diagnostics(diagnostics, settings):
    """
    Apply max-matches, dedup, render, output, and compute exit code.

    Returns (rendered_string, exit_code).
    """
    diags = diagnostics

    # Apply max-matches limit
    max_matches = settings.get("max_matches", 0)
    if max_matches > 0 and len(diags) > max_matches:
        log_info("Truncating to %d matches" % max_matches)
        diags = diags[:max_matches]

    # Apply dedup
    if settings.get("dedup", True):
        before_count = len(diags)
        diags = text_dedup_diagnostics(diags)
        after_count = len(diags)
        if before_count != after_count:
            log_debug("Deduplication: %d -> %d diagnostics" % (before_count, after_count))

    # Clean up metadata fields before rendering
    for diag in diags:
        if "_tag" in diag:
            diag.pop("_tag")
        if "_captures" in diag:
            diag.pop("_captures")
        if "_url" in diag:
            diag.pop("_url")

    # Render
    format_val = settings.get("format", "human")
    rendered = text_render_diagnostics(diags, format = format_val)

    # Print to stdout
    print(rendered)

    # Write to output file if specified
    output_path = settings.get("output_path")
    if output_path:
        log_info("Writing output to: " + output_path)
        fs_write_text(output_path, rendered)

    # Compute exit code
    fail_on = settings.get("fail_on", "error")
    exit_code = compute_exit_code(diags, fail_on)

    return (rendered, exit_code)

def compute_exit_code(diagnostics, fail_on):
    """
    Compute exit code based on fail_on threshold.

    Returns 0 or 1.
    """
    if fail_on == "never":
        return 0

    for diag in diagnostics:
        severity = diag.get("severity", "")

        if fail_on == "error" and severity == "error":
            return 1

        if fail_on == "warning" and severity in ["warning", "error"]:
            return 1

    return 0

# ============================================================================
# Main
# ============================================================================

def main():
    """Main entry point. Returns exit code."""

    # Parse arguments
    spec = make_parser()
    args = args_parse(spec)

    # Validate required arguments
    assert_on(args.get("rules") != None, "--rules is required")
    assert_on(args.get("input") != None, "--input is required")

    rules_path = args.get("rules", "")
    input_path = args.get("input", "")

    log_info("Loading rules from: " + rules_path)

    # Load and validate configuration
    cfg = load_config(rules_path)
    validate_rules(cfg["rule"])
    validate_causes(cfg["cause"])

    # Resolve settings
    settings = resolve_settings(args, cfg)

    # Add output path to settings if specified
    if args.get("output"):
        settings["output_path"] = args["output"]

    log_debug("Settings: format=%s, fail_on=%s, dedup=%s, strip_ansi=%s" %
              (settings["format"], settings["fail_on"], settings["dedup"], settings["strip_ansi"]))

    # Stage input
    scan_path = stage_input(input_path, settings["strip_ansi"])

    # Scan for matches
    matches = scan_file(scan_path, cfg["rule"])

    # Convert to diagnostics
    diagnostics = matches_to_diagnostics(matches, cfg["rule"], settings["source"])

    log_info("Generated %d diagnostics" % len(diagnostics))

    # Apply cause hints
    diagnostics = apply_causes(diagnostics, cfg["cause"])

    # Finalize and render
    rendered, exit_code = finalize_diagnostics(diagnostics, settings)

    # Cleanup temp files
    tmp_cleanup_all()

    return exit_code

# Run main
exit_code = main()
sys_exit(exit_code)

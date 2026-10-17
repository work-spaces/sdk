---
name: spaces-exec
description: Use when writing or editing Spaces executable Starlark scripts (`*.exec.star` files with a `#!/usr/bin/env spaces` shebang) built on `//@star/prelude/exec/*.star`, `//@star/prelude/info.star`, and `//@star/prelude/semver.star`. Covers script structure, argument parsing conventions, choosing prelude functions, Starlark dialect gotchas, and validation.
---

# Spaces Executable Scripts

Spaces exec scripts are Starlark programs run directly by the `spaces` binary. The prelude modules are thin wrappers around Rust functions compiled into `spaces`, so a script should read as an expressive composition of prelude calls rather than reimplementing logic or shelling out to other tools.

## Script Layout

Every script follows this exact shape, in this order:

1. Shebang `#!/usr/bin/env spaces` on line 1.
2. A module docstring describing what the script does.
3. `load(...)` statements: one per module, sorted by module path, loading only the symbols used (sorted alphabetically). Use the multi-line form when a load has many symbols.
4. Private module constants, named `_UPPER_SNAKE`.
5. Private helper functions, named `def _some_function(...)`.
6. `def main() -> int:` with a docstring.
7. `sys_exit(main())` as the last line.

No other top-level logic. Everything executable lives in `main()` or `_` helpers.

Naming and execution:

- Name files `<kebab-name>.exec.star`. The `.star` extension is required for `spaces` to run the file.
- Make the file executable (`chmod +x`). Run it as `./name.exec.star ...` or `spaces name.exec.star ...`.
- Use the file name as the `name` passed to `args_parser`.

## Template

```python
#!/usr/bin/env spaces
"""
Write a JSON manifest of sha256 digests for files matching glob patterns.
"""

load(
    "//@star/prelude/exec/args.star",
    "args_flag",
    "args_list",
    "args_opt",
    "args_parse",
    "args_parser",
    "args_pos",
)
load("//@star/prelude/exec/fs.star", "fs_read_globs", "fs_write_json")
load("//@star/prelude/exec/hash.star", "hash_sha256_file")
load("//@star/prelude/exec/io.star", "io_print")
load("//@star/prelude/exec/log.star", "log_error", "log_info")
load("//@star/prelude/exec/path.star", "path_relative_to")
load("//@star/prelude/exec/sys.star", "sys_exit")
load("//@star/prelude/info.star", "info_get_platform_name")

_DEFAULT_OUTPUT = "manifest.json"

def _collect_digests(root: str, includes: list[str], excludes: list[str]) -> dict[str, str]:
    digests = {}
    for file in fs_read_globs(includes, excludes = excludes, root = root):
        digests[path_relative_to(file, root)] = hash_sha256_file(file)
    return digests

def main() -> int:
    """
    Hash files under a root directory and write a manifest.

    Returns:
        0 on success, 1 when no files match.
    """
    parsed = args_parse(args_parser(
        name = "hash-manifest.exec.star",
        description = "Write a JSON manifest of sha256 digests for files matching glob patterns.",
        options = [
            args_list("--include", help = "Glob pattern to include (repeatable)."),
            args_list("--exclude", help = "Glob pattern to exclude (repeatable)."),
            args_opt("--output", default = _DEFAULT_OUTPUT, help = "Path to the manifest file."),
            args_flag("--dry-run", help = "Print the manifest instead of writing it."),
        ],
        positional = [args_pos("root", required = True)],
    ))

    root = parsed["root"]
    includes = parsed["include"] if parsed["include"] else ["**/*"]
    digests = _collect_digests(root, includes, parsed["exclude"])
    if not digests:
        log_error("No files matched under {}".format(root))
        return 1

    manifest = {"platform": info_get_platform_name(), "files": digests}
    if parsed["dry_run"]:
        io_print(str(manifest))
        return 0

    fs_write_json(parsed["output"], manifest)
    log_info("Wrote {} entries to {}".format(len(digests), parsed["output"]))
    return 0

sys_exit(main())
```

## Command-Line Arguments

Build the parser inside `main()` with `args_parser(name, description, options, positional)` and call `args_parse` once.

- **Long names only.** Do not pass `short=` to `args_flag`, `args_opt`, or `args_list` unless the user explicitly asks for a short form. `-h`/`--help` is provided automatically.
- **No aliases.** One option per concept. Never add a second option that means the same thing as another (e.g. `--out` alongside `--output`, `--quiet` alongside `--verbose=false`).
- **No extraneous options.** Only add arguments the task requires. Don't add speculative `--verbose`, `--force`, `--config`, etc.
- Always provide `help=` for each option, as a short sentence.
- Pick the right descriptor:
  - `args_flag("--name")` → `bool`, default `False`.
  - `args_opt("--name", type = "str" | "int" | "bool", default = ..., choices = [...])` → single value. Without `default`, the value is `""`, `0`, or `False`.
  - `args_list("--name")` → repeatable, always a list (default `[]`).
  - `args_pos("name", required = True)` → positional; `variadic = True` must be last and yields a list. Optional, non-variadic positionals are `None` when omitted.
- Prefer `args_pos(..., required = True)` for mandatory inputs. Options have no `required` parameter; if a mandatory value must be an option, check for the empty default in `main()`, `log_error(...)`, and `return 2`.
- Parsed keys are the long name without `--` and with `-` replaced by `_`: `--dry-run` → `parsed["dry_run"]`. Index directly (`parsed["dry_run"]`); every declared argument is always present.
- `args_parse` exits `0` on `--help` and `2` on usage errors by itself; don't handle those.

## Choosing Prelude Functions

Load paths:

- `//@star/prelude/exec/<module>.star` for exec modules.
- `//@star/prelude/info.star` and `//@star/prelude/semver.star`.

These are embedded in the `spaces` binary, so they resolve whether or not the script runs inside a workspace. In a workspace, the source is under `@star/prelude/`. **Before using a function, read its definition in that file to confirm the exact signature and return shape.** Only use functions that are actually defined with `def` there; some docstrings mention functions that don't exist (e.g. `process_exec`).

Prefer a prelude function over spawning a process whenever one exists (read/write files, hashing, globbing, JSON/TOML/YAML, path manipulation, string/regex, temp files, timing).

| Module | Use for | Key functions |
|---|---|---|
| `args` | CLI parsing | `args_parser`, `args_parse`, `args_flag`, `args_opt`, `args_list`, `args_pos`, `args_argv`, `args_program` |
| `sys` | Exit, host info | `sys_exit`, `sys_os`, `sys_arch`, `sys_is_ci`, `sys_cpu_count`, `sys_hostname`, `sys_username`, `sys_user_home`, `sys_info` |
| `log` | Diagnostics | `log_trace`, `log_debug`, `log_info`, `log_warn`, `log_error`, `log_fatal`, `log_set_level`, `log_set_format` |
| `io` | Program output and stdin | `io_print`, `io_eprint`, `io_write_stdout`, `io_read_stdin_to_string`, `io_read_stdin_lines`, `io_stdin_is_terminal` |
| `fs` | Files and directories | `fs_read_text`, `fs_write_text`, `fs_write_string_atomic`, `fs_read_lines`, `fs_read_json`/`yaml`/`toml`, `fs_write_json`/`yaml`/`toml`, `fs_exists`, `fs_is_file`, `fs_is_directory`, `fs_read_directory`, `fs_read_globs`, `fs_walk_directory`, `fs_mkdir`, `fs_copy`, `fs_move`, `fs_remove`, `fs_symlink`, `fs_chmod`, `fs_metadata`, `fs_with_file_lock` |
| `path` | Path manipulation | `path_join`, `path_dirname`, `path_basename`, `path_stem`, `path_extension`, `path_with_extension`, `path_absolute`, `path_canonicalize`, `path_relative_to`, `path_parent`, `path_expand_user` |
| `env` | Environment and cwd | `env_get`, `env_has`, `env_all`, `env_cwd`, `env_chdir`, `env_which`, `env_path_list` |
| `process` | Running programs (argv, no shell) | `process_options`, `process_run`, `process_capture`, `process_spawn`, `process_wait`, `process_read_lines`, `process_kill`, `process_pipeline`, `process_stdout_*`, `process_stderr_*` |
| `sh` | Shell one-liners | `sh_run`, `sh_capture`, `sh_lines`, `sh_exit_code`, `sh_pipe` |
| `string` | String helpers and regex | `string_trim`, `string_split_lines`, `string_replace`, `string_regex_match`, `string_regex_find_all`, `string_regex_captures`, case conversions, `string_pad_left`/`right`, `string_format_table` |
| `text` | Line-oriented file scanning and diagnostics | `text_scan_file`, `text_grep`, `text_head`, `text_tail`, `text_dedent`, `text_regex_scan*`, `text_diagnostic`, `text_render_diagnostics` |
| `json` / `toml` / `yaml` | Encode/decode | `json_decode`, `json_encode`, `json_try_decode`, `json_merge`, `toml_decode`, `toml_encode`, `yaml_decode`, `yaml_encode`, and `*_merge` |
| `hash` | Digests and encoding | `hash_sha256`, `hash_sha256_file`, `hash_blake3_file`, `hash_md5`, `hash_crc32`, `hash_hex_*`, `hash_base64_*` |
| `time` | Time and timers | `time_now`, `time_now_iso8601`, `time_unix_seconds`, `time_sleep`, `time_format_datetime`, `time_timer_start`, `time_timer_elapsed_ms` |
| `tmp` | Temp files and directories | `tmp_dir`, `tmp_dir_keep`, `tmp_file`, `tmp_cleanup`, `tmp_cleanup_all` |
| `signal` | Signal handling | `signal_trap`, `signal_untrap`, `signal_wait`, `signal_dispatch`, `signal_supported` |
| `info.star` | Platform detection | `info_get_platform_name`, `info_get_supported_platforms`, `info_is_platform_linux`/`macos`/`windows`/`x86_64`/`aarch64`, `info_get_cpu_count`, `info_set_required_semver` |
| `semver.star` | Version logic | `semver_parse`, `semver_compare`, `semver_matches`, `semver_sort`, `semver_max`, `semver_resolve`, `semver_filter`, `semver_bump_*`, `semver_is_prerelease`, `semver_extract_version` |

Guidance:

- **`process` over `sh`.** Use `process_run(process_options(...))` or `process_capture([...])` with an argv list, especially when any argument comes from user input. Use `sh_*` only for true shell features (pipes, redirects, globs) on trusted strings.
- `process_run` returns `{"status", "stdout", "stderr", "duration_ms"}`. Pass `check = True` to fail on non-zero, or inspect `status` and return a meaningful exit code.
- **Output:** use `io_print` for the script's actual output (stdout) and `log_*` for progress and diagnostics. `print()` is overridden and only accepts a `str`.
- **Exec-safe `info` functions only.** In exec scripts there is no workspace evaluation context, so `info_is_ci`, `info_get_execution_phase`, `info_is_execution_phase_*`, `info_get_path_to_store`, `info_get_path_to_spaces_tools`, and `info_set_minimum_version` fail with "no EvalContext". Use `sys_is_ci()` for CI detection. `info_set_max_queue_count` is a no-op for scripts; don't use it.
- `info_set_required_semver(">=X.Y")` is fine to call at the start of `main()` when the script depends on a newer `spaces`.

## Starlark Dialect Rules

The `spaces` dialect is strict; these are verified behaviors:

- **Type annotations are enforced at runtime.** Annotate helper and `main` parameters and return types accurately (`list[str]`, `dict[str, str]`, `str | None`). A mismatch is a runtime error.
- **No f-strings.** Use `"{} {}".format(a, b)`.
- **No `while` loops.** Use `for` over `range(...)` or a list.
- **No `try`/`except`.** Errors abort the script. Check preconditions first (`fs_exists`, `env_has`, `status` codes) and return a non-zero code, or use `fail("message")` / `log_fatal("message")` for unrecoverable errors.
- No `class`, `import`, or `global`. Use dicts and lists. Recursion is allowed but prefer iteration.
- Don't mutate a list or dict while iterating it, or after it has been frozen (module-level values are frozen once loading finishes, so build mutable state inside functions).

## Exit Codes

`main()` returns an `int`:

- `0`: success
- `1`: operational failure (nothing matched, a subprocess failed, a validation failed)
- `2`: usage error detected in `main()` (matches `args_parse`)

Log a clear `log_error` message before returning non-zero.

## Validation

After writing or editing a script, run all of these:

1. `chmod +x <script>.exec.star`
2. `./<script>.exec.star --help` to confirm the parser builds and help text reads well.
3. Run a happy path and at least one failure path; confirm exit codes.
4. Lint and format with buildifier from the workspace sysroot:

   ```sh
   sysroot/bin/buildifier --lint=warn <script>.exec.star
   ```

   Use `--mode=check` to verify without rewriting.

---
name: spaces-rules
description: Use when writing or editing Spaces rule files (`spaces.star`, `*.spaces.star`) or the Starlark function modules they load (`star/*.star`, `star/internal/*.star`), built on `//@star/prelude/rules/*.star`, `//@star/prelude/info.star`, and `//@star/prelude/semver.star`. Covers checkout vs run rule semantics, evaluation order, file placement, deps/labels, and validation.
---

# Spaces Rules

Spaces rule files are Starlark modules that add rules to a dependency graph. There are two kinds of rules, with very different evaluation and execution semantics:

- **Checkout rules** (`checkout_*`) populate the workspace: clone repos, download archives, add assets, and set environment variables. Run by `spaces checkout`, `spaces checkout-repo`, `spaces co`, and `spaces sync`.
- **Run rules** (`run_*`) build, test, and otherwise operate on the workspace. Run by `spaces run`.

The prelude modules are thin wrappers around Rust builtins compiled into `spaces`. **Before using a function, read its definition in `@star/prelude/` to confirm the exact signature, defaults, and return shape.** Only use functions defined with `def` in those files.

## File Types and Placement

| File | Purpose |
|---|---|
| `spaces.star` or `<name>.spaces.star` | Rule files. Only files ending in `spaces.star` are evaluated. |
| `<repo>/star/internal/*.star` | Private function modules used by this repo's rule files. **The default choice.** |
| `<repo>/star/*.star` | Public function modules intended to be loaded by other repos. Use only when the module is meant to be a public API. |

Function modules (`star/**/*.star`) never add rules at load time. They only define functions that rule files call.

### Rule labels

A rule's label is derived from the file that defines it:

- `//spaces.star` → `//:build`
- `//my-repo/spaces.star` → `//my-repo:build`
- `//my-repo/tools.spaces.star` → `//my-repo/tools:build`

In `deps`, use `":rule"` for a rule in the same file and the full `"//path:rule"` for a rule in another file. Built-in aggregate targets are `//:all`, `//:setup`, `//:test`, `//:pre-commit`, and `//:clean`.

### Paths

- `//` prefixes a workspace-root path (`"//sysroot/bin/tool"`, `"//build/out.txt"`).
- Paths without `//` in deps/globs/`working_directory` are relative to the directory of the rule file. Prefer `//` paths whenever the meaning could be ambiguous.
- `workspace_get_path_to_checkout()` returns the workspace path of the repo containing the current module. Use it to build paths to repo-owned files instead of hard-coding the checkout name.

## Checkout Rules

Checkout rules follow these semantics:

- **They MUST be in a repository root.** Only the `*spaces.star` files at the root of the workspace or of a checked-out repo are evaluated during checkout (when `is_evaluate_spaces_modules` isn't `False`). Checkout rules in subdirectories are never run.
- **Files are evaluated single-threaded in lexicographic order.** Control ordering with a numeric prefix (see [Checkout file layout](#checkout-file-layout)).
- **All rules from one file are added to the graph, then the graph executes before the next file is evaluated.** As a result:
  - A later file can `load()` star modules from repos that an earlier file checked out. A file can't load from a repo it checks out itself.
  - A later file can read values stored with `checkout_store_value()` and env vars added by earlier files.
  - Within a single file, use `deps` to order rules (for example, a `chmod` exec that depends on an archive rule).
- **`checkout_add_exec()` always runs during checkout.** It has no `type` parameter, so it can't be made optional. Keep it idempotent and cheap. Use `platforms=` or a Starlark `if` to restrict when it's added.
- Other checkout rules accept `type = checkout_type_optional()` to skip them during checkout.

### Deprecated checkout helpers

Do not use the deprecated SDK-local helpers from `@star/sdk/star/checkout.star`. Use their current prelude replacements instead:

| Deprecated helper | Use instead |
|---|---|
| `checkout_add_asset` | `checkout_add_any_assets` with `asset_content(...)` |
| `checkout_add_hard_link_asset` | `checkout_add_any_assets` with `asset_hard_link(...)` |
| `checkout_add_soft_link_asset` | `checkout_add_any_assets` with `asset_soft_link(...)` |
| `checkout_add_which_asset` | `checkout_add_any_assets` with `asset_which(...)` |
| `checkout_add_target` | `checkout_add` |
| `checkout_update_env` | `checkout_add_env_vars` |

Load and use the replacement functions from `//@star/prelude/rules/checkout.star` (and asset constructors from `//@star/prelude/rules/asset.star`). Do not introduce deprecated helpers in new rule files or function modules, even if existing SDK code still exposes them for backward compatibility.

### Checkout file layout

Split a repo's checkout rules across numbered files at the repo root:

| File | Contents |
|---|---|
| `0.checkout.spaces.star` | Check out SDK repos with `sdk_add_repo()` (`rules/sdk.star`). Only needed when the repo uses Starlark beyond the prelude; `@star/prelude` is checked out automatically. Omit this file otherwise. |
| `1.checkout.spaces.star` | Add SDK tools (loaded from the repos checked out in `0`) and other repos. |
| `X.checkout.spaces.star` | Optional middle steps (`2`, `3`, ...). Checkout rules that need repos or rules from `1.checkout.spaces.star` (for example, loading a module from a repo cloned in `1`, or reading a value it stored). Add one file per extra layer of dependencies. |
| `Y.checkout.spaces.star` | Last file. Call `sdk_finalize_checkout()` here when the SDK requires it. |

Notes:

- Use `sdk_add_repo()` instead of `checkout_add_repo()` for SDKs. When several workspace members check out the same SDK, only the first one clones it and becomes its owner. Later calls do nothing.
- `sdk_finalize_checkout(fn)` calls `fn` only in the repo that owns the SDK, so SDK finalization runs once. It must be called from a file at the repo root, after all tools and repos the SDK needs are in place.
- Names sort as strings, so `10.checkout.spaces.star` sorts before `2.checkout.spaces.star`. Use single digits, or zero-pad every file (`00`, `01`, ...) if there are more than ten.

Key functions in `rules/checkout.star`:

| Function | Use for |
|---|---|
| `checkout_add_repo` | Clone a git repo at `rev`. `name` is also the workspace path. Clone modes come from `checkout_clone_default/worktree/shallow()`. Sparse checkout uses `checkout_sparse_mode_cone/no_cone()`. |
| `checkout_add_archive` | Download and extract a URL with `sha256`, plus `strip_prefix`/`add_prefix`/`includes`/`excludes`. |
| `checkout_add_platform_archive` | Add per-platform archives as a dict keyed by platform name (`"macos-aarch64"`, `"linux-x86_64"`, ...). |
| `checkout_add_oras_archive` | Pull an OCI/oras artifact. |
| `checkout_add_any_assets` | Add hard links, soft links, generated files, and `which` lookups from `rules/asset.star` (`asset_hard_link`, `asset_soft_link`, `asset_content`, `asset_which`, `asset_home`). |
| `checkout_update_asset` | Merge a dict into a JSON/TOML/YAML file (for example, editor settings). Multiple rules may merge into the same file. |
| `checkout_add_env_vars` | Add workspace env vars built with `rules/env.star` (`env_assign`, `env_append`, `env_prepend`, `env_inherit`, `env_script`, `env_aws_config`). |
| `checkout_add_exec` | Run a command during checkout. It always runs. |
| `checkout_add` | Group rules with no action. |
| `checkout_store_value` / `checkout_store_env_or` / `checkout_modify_value` | Persist values for later files and the run phase. Read them with `workspace_load_value*` from `rules/ws.star`. |
| `checkout_update_shell*`, `checkout_add_home_*`, `checkout_set_sandbox` | Configure `spaces shell`, the workspace `HOME`, and the sandbox (`rules/sandbox.star`). |
| `sdk_add_repo` / `sdk_finalize_checkout` (`rules/sdk.star`) | Share one SDK repo across members without duplicate checkouts. |

Example `0.checkout.spaces.star`:

```python
"""
Check out the SDK Starlark repositories.
"""

load("//@star/prelude/rules/sdk.star", "sdk_add_repo")

sdk_add_repo(
    "@star/packages",
    url = "https://github.com/work-spaces/packages",
    rev = "main",
)
```

Example `1.checkout.spaces.star`:

```python
"""
Add SDK tools and other repos.
"""

load("//@star/packages/star/rust.star", "rust_add")
load("//@star/prelude/rules/checkout.star", "checkout_add_env_vars", "checkout_add_repo")
load("//@star/prelude/rules/env.star", "env_append")
load("//@star/prelude/rules/ws.star", "workspace_get_absolute_path")

checkout_add_env_vars(
    "sysroot_env_path",
    vars = [
        env_append(
            "PATH",
            "{}/sysroot/bin".format(workspace_get_absolute_path()),
            help = "Add sysroot/bin to the PATH",
        ),
    ],
)

rust_add("rust_toolchain", version = "1.94")

checkout_add_repo(
    "deps/libexpat",
    url = "https://github.com/libexpat/libexpat",
    rev = "R_2_7_5",
)
```

Example `2.checkout.spaces.star` (the last file):

```python
"""
Finalize the SDK checkout when this repo owns the SDK.
"""

load("//@star/prelude/rules/checkout.star", "checkout_add_exec")
load("//@star/prelude/rules/sdk.star", "sdk_finalize_checkout")

def _finalize_sdk():
    checkout_add_exec(
        "sdk_finalize",
        command = "bash",
        args = ["-c", "echo 'SDK-specific finalization goes here'"],
    )

sdk_finalize_checkout(_finalize_sdk)
```

## Run Rules

Run rules follow these semantics:

- **They can be in any `*spaces.star` file**, including subdirectories.
- **All rule files are evaluated in parallel into one dependency graph.** Evaluation order isn't guaranteed. A file must not depend on side effects from another file's evaluation. Express ordering only through `deps`.
- After evaluation, spaces runs the requested rule and its dependencies.
- **`run_add_exec()` is optional by default** (`type` defaults to `"Optional"`). It runs only when the user names it (`spaces run //path:rule`) or names a rule that depends on it. To include it in a bare `spaces run` (`//:all`), pass `type = run_type_all()` or group rules with `run_add_to_all()`.

Key functions in `rules/run.star`:

| Function | Type / target | Use for |
|---|---|---|
| `run_add_exec` | Optional (default) | General command. `type` is one of `run_type_all/test/setup/precommit()`. Supports `target_files`/`target_dirs`. |
| `run_add_exec_setup` | `//:setup` | Runs once, and all run rules depend on it. |
| `run_add_exec_test` | `//:test` | Tests. |
| `run_add_exec_precommit` | `//:pre-commit` | Format and lint checks. |
| `run_add_exec_clean` | `//:clean` | Clean steps. |
| `run_add` | any | Group dependencies under one name with no command. |
| `run_add_to_all` | `//:all` | Group rules into the default `spaces run`. |
| `run_add_kill_exec` | any | Send a `run_signal_*()` to another running rule (for example, stop a server). |
| `run_add_archive` | Optional | Create an archive. Returns `(archive_path, sha256_path)`. |

Common exec options:

- `help`: always provide a one-line description for user-facing rules. It's shown by `spaces query rules --has-help`.
- `log_level = run_log_level_passthrough()` for interactive or streaming tools (formatters, `clippy`). `run_log_level_app()` prints output with spaces markings.
- `expect = run_expect_failure()` / `run_expect_any()` for commands whose non-zero exit is expected.
- `workspace_vars = ["CARGO_HOME", ...]` copies workspace env vars into `env` when they're set.
- `apply_trailing_args_to` routes `spaces run rule -- args...` to a specific rule.
- Deferred tokens that resolve at execution time: `run_load_file_contents(path)`, `run_load_exit_code(":rule")`, and `run_load_env("VAR")`. The file and rule variants add their dependency automatically.

Example `spaces.star` in a repo:

```python
"""
Build and test rules for my-repo.
"""

load("//@star/prelude/rules/deps.star", "deps_new")
load("//@star/prelude/rules/globs.star", "globs_new")
load("//@star/prelude/rules/run.star", "run_add_exec", "run_add_exec_test", "run_add_to_all")
load("//@star/prelude/rules/visibility.star", "visibility_private")
load("star/internal/cargo.star", "cargo_add_build")

_SOURCES = globs_new(
    includes = ["//my-repo/**/*.rs", "//my-repo/Cargo.toml"],
    excludes = ["//my-repo/target/**"],
)

cargo_add_build("build", sources = _SOURCES)

run_add_exec_test(
    "test",
    command = "cargo",
    args = ["test"],
    deps = deps_new(rules = [":build"], globs = [_SOURCES]),
    help = "Run my-repo unit tests",
)

run_add_exec(
    "fmt",
    command = "cargo",
    args = ["fmt"],
    log_level = "Passthrough",
    help = "Format my-repo sources",
    visibility = visibility_private(),
)

run_add_to_all("default", deps = [":build"])
```

## Dependencies and Caching

- `deps` is either a plain `list[str]` of rule labels or the `list[dict]` returned by `rules/deps.star`. Don't mix the two forms in one list.
- `deps_new(rules = [...], globs = [globs_new(...)], files = [...])` (`rules/deps.star`, `rules/globs.star`) declares rule and file inputs. A rule whose glob and file deps are unchanged is skipped. Without glob or file deps, the rule runs every time.
- `deps_run_once(rules = [...])` runs a rule once and then skips it.
- Declare outputs with `target_files` / `target_dirs` on `run_add_exec` so dependents rebuild correctly.
- `globs_new` replaces the deprecated `glob()` and `deps_glob()`. `deps_new` replaces the deprecated `deps()`.

## Function Modules

Wrap repeated or multi-rule patterns in a function in `star/internal/<topic>.star`. Use `star/<topic>.star` only for intentionally public APIs.

- **Load paths:** load the prelude and other repos with `//` workspace-root paths (`//@star/prelude/rules/run.star`). Load a repo's own modules with paths relative to the loading file (`load("star/internal/cargo.star", ...)` from the repo root, or `load("other.star", ...)` from inside `star/internal/`). Relative paths stay correct no matter where the repo is checked out.
- **Signature:** prefix the function with the module topic (`cargo_add_build`). Take `name: str` first. End with `deps: list[str] = []` and `visibility: str | dict[str, list[str]] | None = None`, and pass both through.
- **Derived rule names:** name helper rules `"{}_<suffix>".format(name)`. Restrict them with `visibility_rules([...])` so only the public rule (`name`) is visible. `rules/rules.star` (`rules_new`, `rules_as_dep`, ...) can return the set of created rules to callers.
- **Docstrings:** give every public function a docstring with `Args:`, and `Returns:` when it returns a value. Name private helpers and constants with a leading `_`.

Example `star/internal/cargo.star`:

```python
"""
Private cargo rule helpers for my-repo.
"""

load("//@star/prelude/rules/deps.star", "deps_new")
load("//@star/prelude/rules/run.star", "run_add_exec")
load("//@star/prelude/rules/visibility.star", "visibility_rules")

def cargo_add_build(
        name: str,
        sources: dict,
        deps: list[str] = [],
        visibility: str | dict[str, list[str]] | None = None):
    """
    Adds a cargo check + build rule pair.

    Args:
        name: The name of the build rule.
        sources: globs_new() describing the build inputs.
        deps: Additional rule dependencies.
        visibility: Rule visibility. See visibility.star.
    """
    check_rule = "{}_check".format(name)

    run_add_exec(
        check_rule,
        command = "cargo",
        args = ["check"],
        deps = deps_new(rules = deps, globs = [sources]),
        visibility = visibility_rules([name]),
    )

    run_add_exec(
        name,
        command = "cargo",
        args = ["build"],
        deps = deps_new(rules = [":" + check_rule], globs = [sources]),
        help = "Build with cargo",
        visibility = visibility,
    )
```

## Supporting Prelude Modules

| Module | Key functions |
|---|---|
| `rules/visibility.star` | `visibility_public()`, `visibility_private()`, `visibility_rules([...])` |
| `rules/ws.star` | `workspace_get_absolute_path`, `workspace_get_path_to_checkout`, `workspace_get_env_var[_or/_or_none]`, `workspace_is_env_var_set[_to]`, `workspace_load_value[_or/s]`, `workspace_get_path_to_member*`, `workspace_assert_member_semver/revision`, `workspace_get_path_to_log_file` |
| `info.star` | `info_is_platform_linux/macos/windows/x86_64/aarch64`, `info_get_platform_name`, `info_get_supported_platforms`, `info_get_cpu_count`, `info_is_ci`, `info_get_path_to_store`, `info_get_execution_phase` / `info_is_execution_phase_checkout/run/inspect`, `info_set_minimum_version`, `info_set_required_semver`, `info_set_max_queue_count` |
| `semver.star` | `semver_parse`, `semver_compare`, `semver_matches[_all]`, `semver_sort`, `semver_max/min`, `semver_filter`, `semver_resolve[_all]`, `semver_bump_*`, `semver_is_prerelease`, `semver_extract_version`, `semver_is_valid_version/requirement`, `semver_validate_requirements` |

Guidance:

- Branch on platform with `info_is_platform_*()` or pass `platforms = ["macos-aarch64", ...]`. Don't shell out to `uname`.
- Use `info_is_ci()` to make interactive conveniences (shell shortcuts, sccache) local-only, and to make secrets `is_required` in CI.
- Call `info_set_required_semver(">=X.Y")` at the top of a rule file that depends on newer `spaces` behavior.
- Use `semver_*` to choose or validate versions (for example, `semver_resolve(available, ["^1.2"])`) instead of comparing strings.

## Starlark Dialect Rules

- **Type annotations are enforced at runtime.** Annotate function parameters and returns accurately.
- **No f-strings.** Use `"{}".format(...)`.
- Don't use `while`, `try`/`except`, `class`, `import`, or `global`. Use `fail("message")` for unrecoverable configuration errors.
- Top-level `if` is allowed in rule files (for example, `if info_is_platform_linux():`). Keep top-level logic declarative: constants, conditionals, and rule calls.
- Module-level values are frozen after loading. Build mutable lists and dicts inside functions.
- Put loads first, sorted by module path, with symbols sorted alphabetically. Use the multi-line form for long symbol lists.

## Validation

After writing or editing rules, run as many of these as practical:

1. `spaces query rules` evaluates all rule files and lists run rules. Add `--checkout` to include checkout rules, `--has-help` to show only user-facing rules, or `--filter='//my-repo/**'` to narrow the list.
2. `spaces query rule //path:rule --deps` confirms the resolved deps, args, env, and type. Add `--checkout` for checkout rules.
3. `spaces query graph //path:rule` confirms the dependency tree is what you intended.
4. For checkout changes: `spaces sync` reruns checkout rules in the existing workspace.
5. For run changes: `spaces run //path:rule`, then rerun it to confirm caching skips it when its inputs haven't changed.
6. Lint and format: `sysroot/bin/buildifier --lint=warn <file>.star` (use `--mode=check` to verify without rewriting).

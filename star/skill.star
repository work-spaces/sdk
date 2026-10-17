"""
Function modules for registering and managing workspace skills.
"""

load("//@star/prelude/rules/run.star", "run_add_exec")
load("//@star/prelude/rules/visibility.star", "visibility_rules")
load("//@star/prelude/rules/ws.star", "workspace_get_absolute_path")
load("asset.star", "asset_soft_link")
load("checkout-config.star", "checkout_config_load_option", "checkout_config_register_optin")
load("checkout.star", "checkout_add_any_assets")

def _skill_validate_name(name: str) -> None:
    if name == "" or "/" in name or name in [".", ".."]:
        fail("skill name must be a non-empty directory name")

def _skill_source_path(path: str) -> str:
    if path.startswith("//"):
        return "{}/{}".format(workspace_get_absolute_path(), path[2:])

    if path.startswith("/") or (len(path) > 1 and path[1] == ":"):
        return path

    return "{}/{}".format(workspace_get_absolute_path(), path)

def _skill_add_activate_rules(
        name: str,
        source: str,
        deps: list[str],
        visibility: str | dict[str, list[str]] | None):
    activate_name = "{}_activate".format(name)
    activate_dir_name = "{}_activate_dir".format(name)

    run_add_exec(
        activate_dir_name,
        command = "mkdir",
        args = ["-p", ".agents/skills"],
        deps = deps,
        working_directory = workspace_get_absolute_path(),
        visibility = visibility_rules([activate_name]),
    )

    run_add_exec(
        activate_name,
        command = "ln",
        args = ["-sfn", source, ".agents/skills/{}".format(name)],
        deps = deps + [":" + activate_dir_name],
        help = "Activate the {} skill".format(name),
        working_directory = workspace_get_absolute_path(),
        visibility = visibility,
    )

def _skill_add_deactivate_rule(
        name: str,
        deps: list[str],
        visibility: str | dict[str, list[str]] | None):
    run_add_exec(
        "{}_deactivate".format(name),
        command = "rm",
        args = ["-f", ".agents/skills/{}".format(name)],
        deps = deps,
        help = "Deactivate the {} skill".format(name),
        working_directory = workspace_get_absolute_path(),
        visibility = visibility,
    )

def skill_activate(
        name: str,
        path: str,
        deps: list[str] = [],
        visibility: str | dict[str, list[str]] | None = None):
    """
    Adds a run rule that links a skill into `.agents/skills/<name>`.

    Args:
        name: The skill name and destination directory name.
        path: A workspace-relative path, `//` workspace-root path, or absolute
            path to the directory containing `SKILL.md`.
        deps: Additional rule dependencies.
        visibility: Rule visibility. See visibility.star.
    """
    _skill_validate_name(name)
    if path == "":
        fail("skill path must point to a directory containing SKILL.md")

    _skill_add_activate_rules(name, _skill_source_path(path), deps, visibility)

def skill_deactivate(
        name: str,
        deps: list[str] = [],
        visibility: str | dict[str, list[str]] | None = None):
    """
    Adds a run rule that removes the skill link from `.agents/skills/<name>`.

    Args:
        name: The skill name and destination directory name.
        deps: Additional rule dependencies.
        visibility: Rule visibility. See visibility.star.
    """
    _skill_validate_name(name)
    _skill_add_deactivate_rule(name, deps, visibility)

def skill_register_checkout(
        name: str,
        path: str,
        config_key: str,
        deps: list[str] = [],
        visibility: str | dict[str, list[str]] | None = None):
    """
    Adds the checkout soft link for a skill when its opt-in option is enabled.


    Args:
        name: The skill name and destination directory name.
        path: A workspace-relative path, `//` workspace-root path, or absolute
            path to the directory containing `SKILL.md`.
        config_key: The name of a registered opt-in checkout configuration option.
        deps: Additional checkout rule dependencies.
        visibility: Rule visibility. See visibility.star.
    """
    _skill_validate_name(name)

    if path == "":
        fail("skill path must point to a directory containing SKILL.md")

    if checkout_config_load_option(config_key):
        checkout_add_any_assets(
            "{}_checkout".format(name),
            assets = [asset_soft_link(
                source = _skill_source_path(path),
                destination = ".agents/skills/{}".format(name),
            )],
            deps = deps,
            visibility = visibility,
        )

def skill_register_run(
        name: str,
        path: str,
        deps: list[str] = [],
        visibility: str | dict[str, list[str]] | None = None):
    """
    Adds run rules to activate and deactivate a skill.

    Args:
        name: The skill name and destination directory name.
        path: A workspace-relative path, `//` workspace-root path, or absolute
            path to the directory containing `SKILL.md`.
        deps: Additional run rule dependencies.
        visibility: Rule visibility. See visibility.star.
    """
    _skill_validate_name(name)

    if path == "":
        fail("skill path must point to a directory containing SKILL.md")

    source = _skill_source_path(path)
    _skill_add_activate_rules(name, source, deps, visibility)
    _skill_add_deactivate_rule(name, deps, visibility)

def skill_register_checkout_spaces_skills() -> None:
    """
    Registers the Spaces skills for conditional checkout under one opt-in option.

    Args:
        name: The registered opt-in checkout configuration option to associate
            with both skills.
    """

    config_key = "SDK_SPACES_SKILLS"

    checkout_config_register_optin(
        config_key,
        help = "Enable spaces exec/rules skills defined in @star/sdk",
    )

    skill_register_checkout(
        "spaces_exec",
        path = "//@star/sdk/skills/spaces-exec",
        config_key = config_key,
    )
    skill_register_checkout(
        "spaces_rules",
        path = "//@star/sdk/skills/spaces-rules",
        config_key = config_key,
    )

def skill_register_run_spaces_skills() -> None:
    """
    Registers activate and deactivate run rules for the Spaces skills.
    """
    skill_register_run("spaces_exec", path = "//@star/skills/spaces-exec")
    skill_register_run("spaces_rules", path = "//@star/skills/spaces-rules")

"""
Run helpers re-exported from the rules prelude.

This module re-exports most helpers from `//@star/prelude/rules/run.star`
and keeps a subset of SDK-local wrappers for backward compatibility.
"""

load(
    "//@star/prelude/rules/run.star",
    "run_add",  # @unused
    "run_add_archive",  # @unused
    "run_add_exec",  # @unused
    "run_add_exec_clean",  # @unused
    "run_add_exec_precommit",  # @unused
    "run_add_exec_setup",  # @unused
    "run_add_exec_test",  # @unused
    "run_add_kill_exec",  # @unused
    "run_add_to_all",  # @unused
    "run_expect_any",  # @unused
    "run_expect_failure",  # @unused
    "run_expect_success",  # @unused
    "run_inputs_always",  # @unused
    "run_inputs_once",  # @unused
    "run_load_exit_code",  # @unused
    "run_load_file_contents",  # @unused
    "run_log_level_app",  # @unused
    "run_log_level_passthrough",  # @unused
    "run_signal_abort",  # @unused
    "run_signal_alarm",  # @unused
    "run_signal_hup",  # @unused
    "run_signal_int",  # @unused
    "run_signal_kill",  # @unused
    "run_signal_quit",  # @unused
    "run_signal_terminate",  # @unused
    "run_signal_user1",  # @unused
    "run_signal_user2",  # @unused
    "run_type_all",  # @unused
    "run_type_precommit",  # @unused
    "run_type_setup",  # @unused
    "run_type_test",  # @unused
)
load("info.star", "info_set_minimum_version")
load("visibility.star", "visibility_private")

RUN_TYPE_TEST = "Test"
RUN_TYPE_PRECOMMIT = "PreCommit"

def run_add_target(
        name: str,
        deps: list[str],
        help: str | None = None,
        type: str | None = None,
        platforms: list[str] | None = None,
        visibility: str | dict[str, list[str]] | None = None):
    """
    Adds a target to the workspace.

    This rule can be used to consolidate dependencies into a single target.

    Args:
        name: The name of the rule.
        deps: List of dependencies for the target.
        platforms: List of platforms to build the target for (default is all).
        type: See [run_add_exec()](#run_add_exec)
        help: The help message for the rule.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visibility.star for more info.
    """
    if visibility != None:
        info_set_minimum_version("0.15.24")
    EFFECTIVE_VISIBILITY = {"visibility": visibility} if visibility != None else {}

    run.add_target(
        rule = {
            "name": name,
            "deps": deps,
            "platforms": platforms,
            "type": type,
            "help": help,
        } | EFFECTIVE_VISIBILITY,
    )

def run_add_target_test(
        name: str,
        deps: list[str],
        help: str | None = None,
        platforms: list[str] | None = None,
        visibility: str | dict[str, list[str]] | None = None):
    """
    Adds a target to the workspace that `//:test` will depend on.

    This rule can be used to consolidate test dependencies into a single target.

    Args:
        name: The name of the rule.
        deps: List of dependencies for the target.
        platforms: List of platforms to build the target for (default is all).
        help: The help message for the rule.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visibility.star for more info.
    """
    run_add_target(
        name,
        deps = deps,
        help = help,
        type = RUN_TYPE_TEST,
        platforms = platforms,
        visibility = visibility,
    )

def run_add_target_precommit(
        name: str,
        deps: list[str],
        help: str | None = None,
        platforms: list[str] | None = None,
        visibility: str | dict[str, list[str]] | None = None):
    """
    Adds a target to the workspace that `//:pre-commit` will depend on.

    This rule can be used to consolidate PreCommit dependencies into a single target.

    Args:
        name: The name of the rule.
        deps: List of dependencies for the target.
        platforms: List of platforms to build the target for (default is all).
        help: The help message for the rule.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visibility.star for more info.
    """
    run_add_target(
        name,
        deps = deps,
        help = help,
        type = RUN_TYPE_PRECOMMIT,
        platforms = platforms,
        visibility = visibility,
    )

def run_add_from_clone(
        name: str,
        clone_from: str,
        deps: list[str] | list[dict] = [],
        help: str | None = None,
        type: str | None = None,
        visibility: str | dict[str, list[str]] | None = None):
    """
    Adds a rule that clones the exec from an existing rule.

    The new rule is merged with the cloned rule: the new rule's fields take precedence,
    and the exec/target is taken from the cloned rule. Dependencies are extended (not replaced).

    Args:
        name: The name of the new rule.
        clone_from: The name of an existing rule to clone the exec from.
        deps: Additional dependencies to add to the cloned rule's dependencies.
        help: The help message for the rule (defaults to cloned rule's help).
        type: The exec type (Run|Setup|Optional (default)|PreCommit|Clean|Test). Defaults to cloned rule's type.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visibility.star for more info.
    """

    info_set_minimum_version("0.15.28")

    run.add_from_clone(
        rule = {
            "name": name,
            "deps": deps,
            "help": help,
            "type": type,
            "visibility": visibility,
        },
        clone_from = clone_from,
    )

def run_add_serialized(
        name: str,
        rules: list[str],
        deps: list[str] | list[dict] = [],
        help: str | None = None,
        type: str | None = None,
        visibility: str | dict[str, list[str]] | None = None):
    """
    Takes a list of existing rules and creates a serial execution chain.

    The first rule in the list is not cloned. Each subsequent rule is cloned
    with an additional dependency on the previous rule in the chain, ensuring
    they execute one after another in order.

    The cloned rules are named `<name>_<index>` where `<index>` is the position
    in the list (starting from 1).

    Args:
        name: The base name used to derive cloned rule names (`<name>_1`, `<name>_2`, ...).
        rules: List of existing rule names to serialize.
        deps: Additional dependencies to add to every cloned rule.
        help: The help message for cloned rules (defaults to cloned rule's help).
        type: The exec type (Run|Setup|Optional (default)|PreCommit|Clean|Test). Defaults to cloned rule's type.
        visibility: Rule visibility: `Public|Private|Rules[]`. See visibility.star for more info.
    """

    if len(rules) == 0:
        return

    # The first rule is not cloned - it runs as-is
    previous_rule = rules[0]

    # Each subsequent rule is cloned with a dependency on the previous rule
    clone_name = None
    for rule_name in rules[1:]:
        sanitized = rule_name.replace("/", "_").replace(":", "_")
        clone_name = "{}_{}".format(name, sanitized)
        run_add_from_clone(
            name = clone_name,
            clone_from = rule_name,
            deps = [previous_rule] + deps,
            help = None,
            visibility = visibility_private(),
        )
        previous_rule = clone_name

    run_add_target(
        name,
        deps = [clone_name],
        help = help,
        type = type,
        visibility = visibility,
    )

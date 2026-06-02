"""
Environment helpers re-exported from the rules prelude.

This module provides a stable SDK import surface for
`//@star/prelude/rules/env.star`.
"""

load(
    "//@star/prelude/rules/env.star",
    "env_append",  # @unused
    "env_assign",  # @unused
    "env_inherit",  # @unused
    "env_prepend",  # @unused
    "env_script",  # @unused
)

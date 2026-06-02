"""
Dependency helpers re-exported from the rules prelude.

This module provides a stable SDK import surface for
`//@star/prelude/rules/deps.star`.
"""

load(
    "//@star/prelude/rules/deps.star",
    "deps",  # @unused
    "deps_glob",  # @unused
    "deps_run_once",  # @unused
)

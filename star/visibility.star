"""
Visibility helpers re-exported from the rules prelude.

This module provides a stable SDK import surface for
`//@star/prelude/rules/visibility.star`.
"""

load(
    "//@star/prelude/rules/visibility.star",
    "visibility_private",  # @unused
    "visibility_public",  # @unused
    "visibility_rules",  # @unused
)

"""
Asset helpers re-exported from the rules prelude.

This module provides a stable SDK import surface for
`//@star/prelude/rules/asset.star`.
"""

load(
    "//@star/prelude/rules/asset.star",
    "asset_content",  # @unused
    "asset_hard_link",  # @unused
    "asset_home",  # @unused
    "asset_soft_link",  # @unused
    "asset_which",  # @unused
)

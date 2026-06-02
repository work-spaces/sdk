"""
Re-exports `toml` utilities from `//@star/prelude/exec/toml.star`.
"""

load(
    "//@star/prelude/exec/toml.star",
    "toml_parse_string",  # @unused
    "toml_to_string",  # @unused
    "toml_to_string_pretty",  # @unused
    "toml_decode",  # @unused
    "toml_encode",  # @unused
    "toml_encode_compact",  # @unused
    "toml_encode_pretty",  # @unused
    "toml_try_decode",  # @unused
    "toml_is_valid",  # @unused
    "toml_merge",  # @unused
)

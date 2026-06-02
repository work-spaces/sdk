"""
Re-exports `json` utilities from `//@star/prelude/exec/json.star`.
"""

load(
    "//@star/prelude/exec/json.star",
    "json_loads",  # @unused
    "json_dumps",  # @unused
    "json_is_string_json",  # @unused
    "json_decode",  # @unused
    "json_encode",  # @unused
    "json_encode_compact",  # @unused
    "json_encode_pretty",  # @unused
    "json_encode_indented",  # @unused
    "json_is_valid",  # @unused
    "json_try_decode",  # @unused
    "json_read_file",  # @unused
    "json_write_file",  # @unused
    "json_merge",  # @unused
)

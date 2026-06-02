"""
Re-exports `yaml` utilities from `//@star/prelude/exec/yaml.star`.
"""

load(
    "//@star/prelude/exec/yaml.star",
    "yaml_parse_string",  # @unused
    "yaml_to_string",  # @unused
    "yaml_decode",  # @unused
    "yaml_loads",  # @unused
    "yaml_encode",  # @unused
    "yaml_dumps",  # @unused
    "yaml_try_decode",  # @unused
    "yaml_merge",  # @unused
    "yaml_encode_compact",  # @unused
    "yaml_encode_pretty",  # @unused
    "yaml_is_valid",  # @unused
)

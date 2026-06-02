"""
Re-exports `fs` utilities from `//@star/prelude/exec/fs.star`.
"""

load(
    "//@star/prelude/exec/fs.star",
    "fs_read_text",  # @unused
    "fs_write_text",  # @unused
    "fs_append_text",  # @unused
    "fs_write_string_atomic",  # @unused
    "fs_read_bytes",  # @unused
    "fs_write_bytes",  # @unused
    "fs_read_lines",  # @unused
    "fs_write_lines",  # @unused
    "fs_read_json",  # @unused
    "fs_write_json",  # @unused
    "fs_read_yaml",  # @unused
    "fs_write_yaml",  # @unused
    "fs_read_toml",  # @unused
    "fs_write_toml",  # @unused
    "fs_exists",  # @unused
    "fs_is_file",  # @unused
    "fs_is_directory",  # @unused
    "fs_is_symlink",  # @unused
    "fs_is_text_file",  # @unused
    "fs_read_directory",  # @unused
    "fs_mkdir",  # @unused
    "fs_copy",  # @unused
    "fs_move",  # @unused
    "fs_remove",  # @unused
    "fs_symlink",  # @unused
    "fs_read_link",  # @unused
    "fs_metadata",  # @unused
    "fs_size",  # @unused
    "fs_modified",  # @unused
    "fs_touch",  # @unused
    "fs_set_permissions",  # @unused
    "fs_chmod",  # @unused
    "fs_chown",  # @unused
)

"""
Re-exports `tmp` utilities from `//@star/prelude/exec/tmp.star`.
"""

load(
    "//@star/prelude/exec/tmp.star",
    "tmp_dir",  # @unused
    "tmp_dir_keep",  # @unused
    "tmp_file",  # @unused
    "tmp_cleanup",  # @unused
    "tmp_cleanup_all",  # @unused
)

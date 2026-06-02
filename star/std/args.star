"""
Command-line argument utilities re-exported from the execution prelude.

This module provides a stable std import surface for argv/program metadata
and argument parser helpers from `//@star/prelude/exec/args.star`.
"""

load(
    "//@star/prelude/exec/args.star",
    "args_argv",  # @unused
    "args_program",  # @unused
    "args_flag",  # @unused
    "args_opt",  # @unused
    "args_list",  # @unused
    "args_pos",  # @unused
    "args_parser",  # @unused
    "args_parse",  # @unused
)

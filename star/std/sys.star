"""
Re-exports `sys` utilities from `//@star/prelude/exec/sys.star`.
"""

load(
    "//@star/prelude/exec/sys.star",
    "sys_os",  # @unused
    "sys_arch",  # @unused
    "sys_hostname",  # @unused
    "sys_username",  # @unused
    "sys_user_home",  # @unused
    "sys_cpu_count",  # @unused
    "sys_total_memory_bytes",  # @unused
    "sys_total_memory_gb",  # @unused
    "sys_endianness",  # @unused
    "sys_executable",  # @unused
    "sys_is_ci",  # @unused
    "sys_info",  # @unused
    "sys_exit",  # @unused
)

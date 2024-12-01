"""
Add LLVM to your sysroot.
"""

load("//@packages/star/github.com/llvm/llvm-project/packages.star", github_llvm_project_packages = "packages")
load(
    "checkout.star",
    "checkout_add_platform_archive",
    "checkout_update_env",
    "checkout_add_asset",
)

def llvm_add(name, version, toolchain_name = "llvm-toolchain.cmake"):
    """
    Add LLVM to your sysroot.

    Args:
        name (str): The name of the rule.
        version (str): The LLVM version from //@packages/star/llvm.org/llvm
        toolchain_name (str): The name of the toolchain file (default is "llvm-toolchain.cmake").
    """
    checkout_add_platform_archive(
        name,
        platforms = github_llvm_project_packages[version],
    )

    checkout_update_env(
        "{}_update_env".format(name),
        vars = {
            "LLVM_SPACES_WORKSPACE": info.get_absolute_path_to_workspace(),
        },
    )

    toolchain_content = """
set(SYSROOT $ENV{LLVM_SPACES_WORKSPACE}/sysroot)

set(CMAKE_NO_SYSTEM_FROM_IMPORTED ON CACHE INTERNAL "LLVM don't use isystem")
set(CMAKE_C_COMPILER ${SYSROOT}/bin/clang CACHE INTERNAL "LLVM TOOLCHAIN C COMPILER")
set(CMAKE_CXX_COMPILER ${SYSROOT}/bin/clang++ CACHE INTERNAL "LLVM TOOLCHAIN C++ COMPILER")
set(CMAKE_ASM_COMPILER ${SYSROOT}/bin/clang+ CACHE INTERNAL "LLVM TOOLCHAIN ASM COMPILER")
set(CMAKE_AR ${SYSROOT}/bin/llvm-ar CACHE INTERNAL "LLVM TOOLCHAIN AR")
set(CMAKE_RANLIB ${SYSROOT}/bin/llvm-ranlib CACHE INTERNAL "LLVM TOOLCHAIN RANLIB")
set(CMAKE_NM ${SYSROOT}/bin/llvm-nm CACHE INTERNAL "LLVM TOOLCHAIN NM")
set(CMAKE_OBJCOPY ${SYSROOT}/bin/llvm-objcopy CACHE INTERNAL "LLVM TOOLCHAIN OBJCOPY")
set(CMAKE_OBJDUMP ${SYSROOT}/bin/llvm-objdump CACHE INTERNAL "LLVM TOOLCHAIN OBJDUMP")
set(CMAKE_SIZE ${SYSROOT}/bin/llvm-size CACHE INTERNAL "LLVM TOOLCHAIN SIZE")

set(CMAKE_EXE_LINKER_FLAGS_INIT "-fuse-ld=lld")
set(CMAKE_MODULE_LINKER_FLAGS_INIT "-fuse-ld=lld")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "-fuse-ld=lld")
"""

    checkout_add_asset(
        "{}_toolchain".format(name),
        destination = toolchain_name,
        content = toolchain_content,
    )

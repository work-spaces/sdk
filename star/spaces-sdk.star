"""
Add the spaces binary to a workflow
"""

load("checkout.star", "checkout_add_platform_archive")
load("//@packages/star/github.com/work-spaces/spaces/packages.star", "packages")

def spaces_add(name, version):
    """
    Add the spaces binary to a workflow
    
    Args:
        name: The name of the binary
        version: The version of the binary
    """
    
    checkout_add_platform_archive(
        name,
        platforms = packages[version]
    )
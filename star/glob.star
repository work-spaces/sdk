"""
Defines a glob expression object used with deps and targets.
"""

def glob(includes, excludes = []):
    """
    Creates a glob expression object used with deps and targets

    Args:
        includes: `[str]` list of glob expressions to include
        excludes: `[str]` list of glob expressions to exclude

    Returns:
        glob dict that can be passed to create deps and targets.
    """
    return {"Includes": includes, "Excludes": excludes}

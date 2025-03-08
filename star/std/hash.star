"""
Hash std built-in functions
"""


def hash_compute_sha256_from_file(file_path):
    """
    Compute the SHA256 hash of a file

    Args:
        file_path: `str` The path to the file to hash

    Returns:
        `str` The SHA256 hash of the file
    """
    return hash.compute_sha256_from_file(file_path)


def compute_sha256_from_string(value):
    """
    Compute the SHA256 hash of a string

    Args:
        value: `str` The string to hash

    Returns:
        `str` The SHA256 hash of the string
    """
    return hash.compute_sha256_from_string(value)
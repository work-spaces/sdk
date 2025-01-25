"""
Spaces Standard library built-ins
"""


def std_fs_exists(path):
    """
    Check if a file or directory exists

    Args:
        path: path to the file or directory
    
    Returns:
        True if the file or directory exists, False otherwise
    """
    return fs.exists(path)

def std_fs_is_file(path):
    """
    Check if a path is a file

    Args:
        path: path to the file

    Returns:
        True if the path is a file, False otherwise
    """
    return fs.is_file(path)

def std_fs_is_directory(path):
    """
    Check if a path is a directory

    Args:
        path: path to the directory

    Returns:
        True if the path is a directory, False otherwise
    """
    return fs.is_directory(path)

def std_fs_is_symlink(path):
    """
    Check if a path is a symbolic link

    Args:
        path: path to the symbolic link

    Returns:
        True if the path is a symbolic link, False otherwise
    """
    return fs.is_symlink(path)

def std_fs_is_text_file(path):
    """
    Check if a file is a text file

    Args:
        path: path to the file

    Returns:
        True if the file is a text file, False otherwise
    """
    return fs.is_text_file(path)
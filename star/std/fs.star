"""
Spaces Filesystem built-in functions
"""


def fs_read_directory(path):
    """
    Read a directory

    Args:
        path: path to the directory
    
    Returns:
        A list of files and directories in the directory
    """
    return fs.read_directory(path)

def fs_exists(path):
    """
    Check if a file or directory exists

    Args:
        path: path to the file or directory
    
    Returns:
        True if the file or directory exists, False otherwise
    """
    return fs.exists(path)

def fs_is_file(path):
    """
    Check if a path is a file

    Args:
        path: path to the file

    Returns:
        True if the path is a file, False otherwise
    """
    return fs.is_file(path)

def fs_is_directory(path):
    """
    Check if a path is a directory

    Args:
        path: path to the directory

    Returns:
        True if the path is a directory, False otherwise
    """
    return fs.is_directory(path)

def fs_is_symlink(path):
    """
    Check if a path is a symbolic link

    Args:
        path: path to the symbolic link

    Returns:
        True if the path is a symbolic link, False otherwise
    """
    return fs.is_symlink(path)

def fs_is_text_file(path):
    """
    Check if a file is a text file

    Args:
        path: path to the file

    Returns:
        True if the file is a text file, False otherwise
    """
    return fs.is_text_file(path)

def fs_read_toml(path):
    """
    Read a TOML file

    Args:
        path: path to the TOML file

    Returns:
        The parsed TOML object
    """
    return fs.read_toml_to_dict(path)

def fs_read_yaml(path):
    """
    Read a YAML file

    Args:
        path: path to the YAML file

    Returns:
        The parsed YAML object
    """
    return fs.read_yaml_to_dict(path)

def fs_read_json(path):
    """
    Read a JSON file

    Args:
        path: path to the JSON file

    Returns:
        The parsed JSON object
    """
    return fs.read_json_to_dict(path)
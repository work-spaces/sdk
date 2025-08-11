"""
Spaces Filesystem built-in functions
"""


def fs_read_directory(path):
    """
    Read a directory

    Args:
        path: `str` path to the directory

    Returns:
        `[str]` A list of files and directories in the directory
    """
    return fs.read_directory(path)

def fs_exists(path):
    """
    Check if a file or directory exists

    Args:
        path: `str` path to the file or directory

    Returns:
       `bool`  True if the file or directory exists, False otherwise
    """
    return fs.exists(path)

def fs_is_file(path):
    """
    Check if a path is a file

    Args:
        path: `str` path to the file

    Returns:
        `bool` True if the path is a file, False otherwise
    """
    return fs.is_file(path)

def fs_is_directory(path):
    """
    Check if a path is a directory

    Args:
        path: `str` path to the directory

    Returns:
        `bool` True if the path is a directory, False otherwise
    """
    return fs.is_directory(path)

def fs_is_symlink(path):
    """
    Check if a path is a symbolic link

    Args:
        path: `str` path to the symbolic link

    Returns:
        `bool` True if the path is a symbolic link, False otherwise
    """
    return fs.is_symlink(path)

def fs_is_text_file(path):
    """
    Check if a file is a text file

    Args:
        path: `str` path to the file

    Returns:
        `bool` True if the file is a text file, False otherwise
    """
    return fs.is_text_file(path)

def fs_read_toml(path):
    """
    Read a TOML file

    Args:
        path: `str` path to the TOML file

    Returns:
        `dict` The parsed TOML object
    """
    return fs.read_toml_to_dict(path)

def fs_read_yaml(path):
    """
    Read a YAML file

    Args:
        path: `str` path to the YAML file

    Returns:
        `dict` The parsed YAML object
    """
    return fs.read_yaml_to_dict(path)

def fs_read_json(path):
    """
    Read a JSON file

    Args:
        path: `str` path to the JSON file

    Returns:
        `dict` The parsed JSON object
    """
    return fs.read_json_to_dict(path)

def fs_read_text(path):
    """
    Read a text file

    Args:
        path: `str` path to the text file

    Returns:
        `str` The content of the text file
    """
    return fs.read_file_to_string(path)

def fs_write_text(path, content):
    """
    Write a text file

    Args:
        path: `str` path to the text file
        content: `str` content to write to the text file
    """
    return fs.write_string_to_file(path = path, content = content)

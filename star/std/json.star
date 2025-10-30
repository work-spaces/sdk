"""
Spaces JSON built-in functions
"""

def json_loads(value):
    """
    Load a JSON string

    Args:
        value: `str` The JSON string to load

    Returns:
        `dict` The parsed JSON object
    """
    return json.string_to_dict(value)

def json_dumps(value, is_pretty = False):
    """
    Dump a JSON object to a string

    Args:
        value: `dict` The JSON object to dump
        is_pretty: `bool` Whether to pretty print the JSON

    Returns:
        `str` The JSON string
    """
    if is_pretty:
        return json.to_string_pretty(value)
    else:
        return json.to_string(value)

def json_is_string_json(value):
    """
    Check if a string is a JSON object

    Args:
        value: `str` The string to check

    Returns:
        `bool` True if the string is a JSON object, False otherwise
    """
    return json.is_string_json(value)

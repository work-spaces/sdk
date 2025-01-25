"""
Spaces JSON built-in functions
"""

def json_loads(value):
    """
    Load a JSON string

    Args:
        value: The JSON string to load

    Returns:
        The parsed JSON object
    """
    return json.string_to_dict(value)

def json_dumps(value, is_pretty = False):
    """
    Dump a JSON object to a string

    Args:
        value: The JSON object to dump
        is_pretty: Whether to pretty print the JSON
    
    Returns:
        The JSON string
    """
    if is_pretty:
        return json.to_string_pretty(value)
    else:
        return json.to_string(value)

def json_is_string_json(value):
    """
    Check if a string is a JSON object

    Args:
        value: The string to check

    Returns:
        True if the string is a JSON object, False otherwise
    """
    return json.is_string_json(value)
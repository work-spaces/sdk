"""
Spaces JSON module - Ergonomic wrappers for JSON serialization and deserialization

This module provides clean, well-documented functions for working with JSON data
in Starlark scripts. All functions handle errors gracefully and provide clear
feedback when something goes wrong.
"""

# ============================================================================
# Original Functions - Maintained for Backwards Compatibility
# ============================================================================

def json_loads(value: str):
    """
    Load a JSON string

    Args:
        value: The JSON string to load

    Returns:
        The parsed JSON object
    """
    return json.string_to_dict(value)

def json_dumps(value, is_pretty: bool = False):
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

def json_is_string_json(value: str) -> bool:
    """
    Check if a string is a JSON object

    Args:
        value: The string to check

    Returns:
        True if the string is a JSON object, False otherwise
    """
    return json.is_string_json(value)

# ============================================================================
# New Ergonomic Functions
# ============================================================================

def json_decode(json_string: str):
    """
    Parse a JSON string into a Starlark value.

    This function takes a JSON-formatted string and converts it into a Starlark
    value (dictionary, list, string, number, boolean, or None). The JSON must be
    valid or this function will raise an error.

    Args:
        json_string: A valid JSON-formatted string to parse

    Returns:
        A Starlark value representing the parsed JSON data (dict, list, string, number, bool, or None)

    Raises:
        Raises an error if the JSON string is malformed or invalid

    Examples:
        Parse a simple JSON object:
        ```starlark
        user = json_decode('{"name": "Alice", "age": 30}')
        print(user["name"])  # Output: Alice
        ```

        Parse a JSON array:
        ```starlark
        items = json_decode('[1, 2, 3, 4, 5]')
        print(items[0])  # Output: 1
        ```

        Parse nested JSON structures:
        ```starlark
        config = json_decode('''
        {
            "database": {
                "host": "localhost",
                "port": 5432
            },
            "debug": true
        }
        ''')
        print(config["database"]["host"])  # Output: localhost
        ```
    """
    return json.string_to_dict(json_string)

def json_encode(value, pretty: bool = False):
    """
    Convert a dictionary or value into a JSON string.

    This function serializes Starlark dictionaries and other values into
    JSON-formatted strings suitable for output, file storage, or network
    transmission. By default, the output is compact. Use pretty=True for
    human-readable formatting with indentation.

    Args:
        value: The dictionary or Starlark value to encode as JSON
        pretty: If True, returns formatted JSON with indentation and newlines.
                If False (default), returns compact JSON.

    Returns:
        A JSON-formatted string representation of the input value

    Raises:
        Raises an error if the value cannot be serialized to JSON

    Examples:
        Encode a simple dictionary:
        ```starlark
        data = {"name": "Bob", "active": True}
        json_str = json_encode(data)
        print(json_str)  # Output: {"name":"Bob","active":true}
        ```

        Encode with pretty formatting:
        ```starlark
        config = {
            "server": "api.example.com",
            "port": 8080,
            "features": ["auth", "logging"]
        }
        pretty_json = json_encode(config, pretty=True)
        print(pretty_json)
        # Output:
        # {
        #   "server": "api.example.com",
        #   "port": 8080,
        #   "features": [
        #     "auth",
        #     "logging"
        #   ]
        # }
        ```

        Encode nested structures:
        ```starlark
        project = {
            "name": "MyProject",
            "version": "1.0.0",
            "metadata": {
                "author": "Dev Team",
                "created": "2024-01-15"
            }
        }
        json_str = json_encode(project, pretty=True)
        ```
    """
    if pretty:
        return json.to_string_pretty(value)
    else:
        return json.to_string(value)

def json_encode_compact(value):
    """
    Convert a value into a compact JSON string without whitespace.

    This is a convenience function for encoding with minimal whitespace,
    useful for efficient network transmission or compact file storage.
    Equivalent to calling json_encode(value, pretty=False).

    Args:
        value: The dictionary or Starlark value to encode

    Returns:
        A compact JSON string with no extra whitespace

    Examples:
        ```starlark
        data = {"x": 1, "y": 2, "z": 3}
        compact = json_encode_compact(data)
        print(compact)  # Output: {"x":1,"y":2,"z":3}
        ```
    """
    return json.to_string(value)

def json_encode_pretty(value):
    """
    Convert a value into a formatted JSON string with indentation.

    This is a convenience function for creating human-readable JSON output
    with proper indentation and newlines. Equivalent to calling
    json_encode(value, pretty=True).

    Args:
        value: The dictionary or Starlark value to encode

    Returns:
        A formatted JSON string with indentation and newlines

    Examples:
        ```starlark
        app_config = {
            "name": "MyApp",
            "settings": {
                "debug": False,
                "timeout": 30
            },
            "plugins": ["auth", "cache"]
        }
        print(json_encode_pretty(app_config))
        ```
    """
    return json.to_string_pretty(value)

def json_is_valid(json_string: str):
    """
    Check whether a string is valid JSON.

    This function validates a string without parsing it, useful for checking
    JSON validity before attempting to decode it. Returns True if the string
    is valid JSON, False otherwise. Does not raise an error for invalid JSON.

    Args:
        json_string: The string to validate

    Returns:
        True if the string is valid JSON, False otherwise

    Examples:
        Validate user input before processing:
        ```starlark
        user_input = '{"id": 123}'
        if json_is_valid(user_input):
            data = json_decode(user_input)
            print("Successfully parsed:", data)
        else:
            print("Invalid JSON provided")
        ```

        Check various strings:
        ```starlark
        print(json_is_valid('{"key": "value"}'))  # True
        print(json_is_valid('[1, 2, 3]'))         # True
        print(json_is_valid('"text"'))            # True
        print(json_is_valid('123'))               # True
        print(json_is_valid('not json'))          # False
        print(json_is_valid('{broken}'))          # False
        ```

        Safe JSON parsing with validation:
        ```starlark
        def safe_json_decode(text, default=None):
            # Safely decode JSON, returning default on error
            if json_is_valid(text):
                return json_decode(text)
            return default

        result = safe_json_decode('{"x": 1}', {})
        print(result)  # {"x": 1}
        ```
    """
    return json.is_string_json(json_string)

def json_try_decode(json_string: str, default = None):
    """
    Attempt to decode a JSON string, returning a default value on failure.

    This function provides safe JSON parsing with graceful error handling.
    If the string is not valid JSON, it returns the default value instead
    of raising an exception.

    Args:
        json_string: The JSON string to decode.
        default: The value to return if decoding fails. Default is None.

    Returns:
        The decoded value if successful, or the default value if decoding fails.

    Example:
        ```starlark
        # Safe parsing with default
        result = json_try_decode('invalid json', default={})
        print(result)  # Output: {}

        # Safe parsing with successful decode
        data = json_try_decode('{"key": "value"}', default={})
        print(data["key"])  # Output: value
        ```
    """
    if json.is_string_json(json_string):
        return json.string_to_dict(json_string)
    return default

def json_merge(dict1, dict2):
    """
    Merge two dictionaries, with values from dict2 overwriting dict1.

    This utility function performs a shallow merge of two dictionaries.
    Values from dict2 override those in dict1. For deep merging of nested
    structures, consider using json_merge recursively.

    Args:
        dict1: The base dictionary.
        dict2: The dictionary to merge in. Its values override dict1's values.

    Returns:
        dict: A new dictionary with merged values.

    Example:
        ```starlark
        defaults = {
            "host": "localhost",
            "port": 8080,
            "debug": False,
        }

        user_config = {
            "port": 9000,
            "debug": True,
        }

        final_config = json_merge(defaults, user_config)
        print(final_config)
        # Output:
        # {
        #     "host": "localhost",
        #     "port": 9000,
        #     "debug": true
        # }
        ```
    """
    result = dict(dict1)
    result.update(dict2)
    return result

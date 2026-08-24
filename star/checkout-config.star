"""
Starlark functions for managing checkout store configuration.

This API uses checkout_store_value() and workspace_load_value() to create clearly documented
checkout configuration.
"""

load("//@star/prelude/rules/checkout.star", "checkout_store_value")
load("//@star/prelude/rules/ws.star", "workspace_load_value")

_DEFAULT_REGISTRY_NAMESPACE = "//checkout-config-registry"
_DEFAULT_NAMESPACE = "//checkout-config"
_TYPE_OPTIN = "optin"
_TYPE_OPTOUT = "optout"
_TYPE_STRING = "string"
_TYPE_ANY = "any"

_ON = "ON"
_OFF = "OFF"

_VALID_TYPES = (_TYPE_OPTIN, _TYPE_OPTOUT, _TYPE_STRING, _TYPE_ANY)

def _option_new(
        help: str,
        type: str):
    """
    Creates a registry entry for a checkout configuration option.

    Args:
        help: Human-readable description of the configuration option.
        type: One of the supported checkout configuration types.

    Returns:
        A dictionary containing the metadata stored in the registry.
    """
    if type not in _VALID_TYPES:
        rlog.warn("Unknown checkout config type `{}`".format(type))

    return {
        "help": help,
        "type": type,
    }

def _load_registered_entry(name: str, registry_namespace: str):
    """
    Loads a registered checkout configuration entry.

    Args:
        name: The configuration option name.
        registry_namespace: The checkout store namespace containing registered options.

    Returns:
        The registered option metadata.
    """
    registered_entry = workspace_load_value(name, registry_namespace)
    if registered_entry == None:
        rlog.warn("Checkout config `{}` has not been registered".format(name))
    return registered_entry

def _load_registered_type(name: str, registry_namespace: str) -> str:
    """
    Loads the registered type for a checkout configuration option.

    Args:
        name: The configuration option name.
        registry_namespace: The checkout store namespace containing registered options.

    Returns:
        The registered configuration type.
    """
    registered_entry = _load_registered_entry(name, registry_namespace)
    if not registered_entry:
        rlog.error("Checkout config `{}` is not registered".format(name))
        fail("checkout config not registered")
    type = registered_entry.get("type")
    if type not in _VALID_TYPES:
        rlog.error("Checkout config `{}` is registered with unknown type `{}`".format(name, type))
        fail("checkout config has bad type")
    return type

def _expect_registered_type(name: str, expected_type: str, registry_namespace: str):
    """
    Validates that a checkout configuration option has the expected type.

    Args:
        name: The configuration option name.
        expected_type: The configuration type required by the caller.
        registry_namespace: The checkout store namespace containing registered options.

    Returns:
        None.
    """
    registered_type = _load_registered_type(name, registry_namespace)
    if registered_type != expected_type:
        rlog.error("Checkout config `{}` is registered as `{}`, not `{}`".format(name, registered_type, expected_type))
        fail("checkout config has wrong type")

def _bool_to_checkout_value(value: bool) -> str:
    """
    Converts a boolean opt-in/out value to its stored checkout representation.

    Args:
        value: The boolean value to store.

    Returns:
        "ON" when value is True, otherwise "OFF".
    """

    if value:
        return _ON
    return _OFF

def _register_entry(name: str, help: str, type: str, namespace: str = _DEFAULT_REGISTRY_NAMESPACE):
    """
    Registers a configuration option.

    Args:
        name: The configuration option name.
        help: Human-readable description of the configuration option.
        type: One of the supported checkout configuration types.
        namespace: The checkout store namespace used for registration metadata.

    Returns:
        None.
    """

    checkout_store_value(
        name,
        value = _option_new(help = help, type = type),
        path = namespace,
    )

def checkout_config_register_optin(name: str, help: str, namespace: str = _DEFAULT_REGISTRY_NAMESPACE):
    """
    Registers an opt-in configuration option.

    Opt-in options load as False unless their stored value is "ON".

    Args:
        name: The configuration option name.
        help: Human-readable description of the configuration option.
        namespace: The checkout store namespace used for registration metadata.

    Returns:
        None.
    """
    _register_entry(name, help, type = _TYPE_OPTIN, namespace = namespace)

def checkout_config_register_optout(name: str, help: str, namespace: str = _DEFAULT_REGISTRY_NAMESPACE):
    """
    Registers an opt-out configuration option.

    Opt-out options load as True unless their stored value is "OFF".

    Args:
        name: The configuration option name.
        help: Human-readable description of the configuration option.
        namespace: The checkout store namespace used for registration metadata.

    Returns:
        None.
    """
    _register_entry(name, help, type = _TYPE_OPTOUT, namespace = namespace)

def checkout_config_register_string(name: str, help: str, namespace: str = _DEFAULT_REGISTRY_NAMESPACE):
    """
    Registers a string configuration option.

    Args:
        name: The configuration option name.
        help: Human-readable description of the configuration option.
        namespace: The checkout store namespace used for registration metadata.

    Returns:
        None.
    """
    _register_entry(name, help, type = _TYPE_STRING, namespace = namespace)

def checkout_config_register_any(name: str, help: str, namespace: str = _DEFAULT_REGISTRY_NAMESPACE):
    """
    Registers a configuration option that can store any value.

    Args:
        name: The configuration option name.
        help: Human-readable description of the configuration option.
        namespace: The checkout store namespace used for registration metadata.

    Returns:
        None.
    """
    _register_entry(name, help, type = _TYPE_ANY, namespace = namespace)

def checkout_config_store_option(
        name: str,
        value,
        namespace: str = _DEFAULT_NAMESPACE,
        registry_namespace: str = _DEFAULT_REGISTRY_NAMESPACE):
    """
    Stores the value of a registered configuration option.

    Args:
        name: The configuration option name.
        value: The value to store. Opt-in and opt-out options require a bool, which is stored as "ON" or "OFF".
        namespace: The checkout store namespace used for stored option values.
        registry_namespace: The checkout store namespace containing registered options.

    Returns:
        None.
    """

    registered_type = _load_registered_type(name, registry_namespace)
    if registered_type == _TYPE_OPTIN or registered_type == _TYPE_OPTOUT:
        checkout_store_value(name, value = _bool_to_checkout_value(value), path = namespace)
        return

    if registered_type == _TYPE_STRING and type(value) != "string":
        rlog.warn("Checkout config `{}` is registered as `string`, got `{}`".format(name, type(value)))

    checkout_store_value(name, value = value, path = namespace)

def checkout_config_store_optin(
        name: str,
        value: bool,
        namespace: str = _DEFAULT_NAMESPACE,
        registry_namespace: str = _DEFAULT_REGISTRY_NAMESPACE):
    """
    Stores a bool for a registered opt-in configuration option.

    Args:
        name: The configuration option name.
        value: The boolean value to store as "ON" or "OFF".
        namespace: The checkout store namespace used for stored option values.
        registry_namespace: The checkout store namespace containing registered options.

    Returns:
        None.
    """
    _expect_registered_type(name, _TYPE_OPTIN, registry_namespace)
    checkout_store_value(name, value = _bool_to_checkout_value(value), path = namespace)

def checkout_config_store_optout(
        name: str,
        value: bool,
        namespace: str = _DEFAULT_NAMESPACE,
        registry_namespace: str = _DEFAULT_REGISTRY_NAMESPACE):
    """
    Stores a bool for a registered opt-out configuration option.

    Args:
        name: The configuration option name.
        value: The boolean value to store as "ON" or "OFF".
        namespace: The checkout store namespace used for stored option values.
        registry_namespace: The checkout store namespace containing registered options.

    Returns:
        None.
    """
    _expect_registered_type(name, _TYPE_OPTOUT, registry_namespace)
    checkout_store_value(name, value = _bool_to_checkout_value(value), path = namespace)

def checkout_config_store_string(
        name: str,
        value: str,
        namespace: str = _DEFAULT_NAMESPACE,
        registry_namespace: str = _DEFAULT_REGISTRY_NAMESPACE):
    """
    Stores a string for a registered string configuration option.

    Args:
        name: The configuration option name.
        value: The string value to store.
        namespace: The checkout store namespace used for stored option values.
        registry_namespace: The checkout store namespace containing registered options.

    Returns:
        None.
    """
    _expect_registered_type(name, _TYPE_STRING, registry_namespace)
    if type(value) != "string":
        rlog.warn("Checkout config `{}` is registered as `string`, got `{}`".format(name, type(value)))
    checkout_store_value(name, value = value, path = namespace)

def checkout_config_store_any(
        name: str,
        value,
        namespace: str = _DEFAULT_NAMESPACE,
        registry_namespace: str = _DEFAULT_REGISTRY_NAMESPACE):
    """
    Stores any value for a registered any configuration option.

    Args:
        name: The configuration option name.
        value: The value to store. Can be any checkout-store-serializable value.
        namespace: The checkout store namespace used for stored option values.
        registry_namespace: The checkout store namespace containing registered options.

    Returns:
        None.
    """
    _expect_registered_type(name, _TYPE_ANY, registry_namespace)
    checkout_store_value(name, value = value, path = namespace)

def checkout_config_load_option(
        name: str,
        namespace: str = _DEFAULT_NAMESPACE,
        registry_namespace: str = _DEFAULT_REGISTRY_NAMESPACE):
    """
    Loads the value of a registered configuration option.

    Args:
        name: The configuration option name.
        namespace: The checkout store namespace containing stored option values.
        registry_namespace: The checkout store namespace containing registered options.

    Returns:
        For opt-in options, True only when the stored value is "ON". For opt-out options, False only when the stored value is "OFF". For string and any options, the stored value or None when no value is stored.
    """

    registered_type = _load_registered_type(name, registry_namespace)
    value = workspace_load_value(name, namespace)

    if registered_type == _TYPE_OPTIN:
        return value == _ON

    if registered_type == _TYPE_OPTOUT:
        return value != _OFF

    return value

def checkout_config_load_optin(
        name: str,
        namespace: str = _DEFAULT_NAMESPACE,
        registry_namespace: str = _DEFAULT_REGISTRY_NAMESPACE) -> bool:
    """
    Loads an opt-in configuration option.

    Args:
        name: The configuration option name.
        namespace: The checkout store namespace containing stored option values.
        registry_namespace: The checkout store namespace containing registered options.

    Returns:
        True only when the stored value is "ON"; otherwise False.
    """
    _expect_registered_type(name, _TYPE_OPTIN, registry_namespace)
    return workspace_load_value(name, namespace) == _ON

def checkout_config_load_optout(
        name: str,
        namespace: str = _DEFAULT_NAMESPACE,
        registry_namespace: str = _DEFAULT_REGISTRY_NAMESPACE) -> bool:
    """
    Loads an opt-out configuration option.

    Args:
        name: The configuration option name.
        namespace: The checkout store namespace containing stored option values.
        registry_namespace: The checkout store namespace containing registered options.

    Returns:
        False only when the stored value is "OFF"; otherwise True.
    """
    _expect_registered_type(name, _TYPE_OPTOUT, registry_namespace)
    return workspace_load_value(name, namespace) != _OFF

def checkout_config_load_string(
        name: str,
        namespace: str = _DEFAULT_NAMESPACE,
        registry_namespace: str = _DEFAULT_REGISTRY_NAMESPACE) -> str | None:
    """
    Loads a string configuration option.

    Args:
        name: The configuration option name.
        namespace: The checkout store namespace containing stored option values.
        registry_namespace: The checkout store namespace containing registered options.

    Returns:
        The stored string value, or None when no value is stored.
    """
    _expect_registered_type(name, _TYPE_STRING, registry_namespace)
    return workspace_load_value(name, namespace)

def checkout_config_load_any(
        name: str,
        namespace: str = _DEFAULT_NAMESPACE,
        registry_namespace: str = _DEFAULT_REGISTRY_NAMESPACE):
    """
    Loads an any configuration option.

    Args:
        name: The configuration option name.
        namespace: The checkout store namespace containing stored option values.
        registry_namespace: The checkout store namespace containing registered options.

    Returns:
        The stored value, or None when no value is stored.
    """
    _expect_registered_type(name, _TYPE_ANY, registry_namespace)
    return workspace_load_value(name, namespace)

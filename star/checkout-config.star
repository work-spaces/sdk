"""
Starlark functions for managing checkout store configuration.

This API uses checkout_store_value() and workspace_load_value() to create clearly documented
checkout configuration.
"""

load(
    "//@star/prelude/rules/checkout.star",
    "checkout_add_exec",
    "checkout_modify_value",
    "checkout_store_env_or",
    "checkout_store_value",
    "checkout_update_asset",
)
load("//@star/prelude/rules/rules.star", "rules_as_dep", "rules_as_rule", "rules_new")
load("//@star/prelude/rules/ws.star", "workspace_load_value")

_DEFAULT_REGISTRY_NAMESPACE = "//checkout-config-registry"
_DEFAULT_NAMESPACE = "//checkout-config"
_TYPE_OPTIN = "optin"
_TYPE_OPTOUT = "optout"
_TYPE_ANY = "any"
_TYPE_ENUM = "enum"
_VALUES = "values"
_REGISTRY_ENTRIES = "entries"
_TYPE_KEY = "type"
_IS_INHERIT_FROM_ENV_KEY = "is_inherit_from_env"
_ENUM_ENTRY_VALUE = "value"
_ENUM_ENTRY_HELP = "help"

_ON = "ON"
_OFF = "OFF"

_VALID_TYPES = (_TYPE_OPTIN, _TYPE_OPTOUT, _TYPE_ANY, _TYPE_ENUM)

def _option_new(
        help: str,
        type: str,
        values = None,
        is_inherit_from_env: bool = False):
    if type not in _VALID_TYPES:
        rlog.warn("Unknown checkout config type `{}`".format(type))

    option = {
        _ENUM_ENTRY_HELP: help,
        _TYPE_KEY: type,
        _IS_INHERIT_FROM_ENV_KEY: is_inherit_from_env,
    }
    if values != None:
        option[_VALUES] = values
    return option

def _load_registry_entries(registry_namespace: str) -> dict:
    registry_entries = workspace_load_value(_REGISTRY_ENTRIES, path = registry_namespace)
    if registry_entries == None:
        return {}

    if type(registry_entries) != "dict":
        rlog.error("Checkout config registry `{}` has invalid `entries` type `{}`; expected `dict`".format(registry_namespace, type(registry_entries)))
        fail("checkout config registry has invalid entries")

    for entry_name, entry in registry_entries.items():
        if type(entry_name) != "string":
            rlog.error("Checkout config registry `{}` has non-string entry key `{}` (type `{}`)".format(registry_namespace, entry_name, type(entry_name)))
            fail("checkout config registry has invalid entries")

        if type(entry) != "dict":
            rlog.error("Checkout config registry `{}` entry `{}` has invalid type `{}`; expected `dict`".format(registry_namespace, entry_name, type(entry)))
            fail("checkout config registry has invalid entries")

    return registry_entries

def _load_registered_entry(name: str, registry_namespace: str):
    registered_entry = _load_registry_entries(registry_namespace).get(name)
    if registered_entry == None:
        rlog.warn("Checkout config `{}` has not been registered".format(name))
    return registered_entry

def _registry_entries_add(current_entries, name: str, entry: dict) -> dict:
    if current_entries == None:
        current_entries = {}
    elif type(current_entries) != "dict":
        rlog.error("Checkout config registry has invalid `entries` type `{}`; expected `dict`".format(type(current_entries)))
        fail("checkout config registry has invalid entries")

    if name in current_entries:
        rlog.error("Checkout config `{}` is already registered".format(name))
        #fail("checkout config already registered")

    updated_entries = dict(current_entries)
    updated_entries[name] = entry
    return updated_entries

def _load_registered_entry_and_type(name: str, registry_namespace: str):
    registered_entry = _load_registered_entry(name, registry_namespace)
    if registered_entry == None:
        rlog.error("Checkout config `{}` is not registered".format(name))
        fail("checkout config not registered")

    if type(registered_entry) != "dict":
        rlog.error("Checkout config `{}` has invalid registry entry type `{}`; expected `dict`".format(name, type(registered_entry)))
        fail("checkout config has invalid registry entry")

    if len(registered_entry) == 0:
        rlog.error("Checkout config `{}` has an empty registry entry".format(name))
        fail("checkout config has invalid registry entry")

    registered_type = registered_entry.get(_TYPE_KEY)
    if registered_type not in _VALID_TYPES:
        rlog.error("Checkout config `{}` is registered with unknown type `{}`".format(name, registered_type))
        fail("checkout config has bad type")

    return registered_entry, registered_type

def _load_registered_type(name: str, registry_namespace: str) -> str:
    _, registered_type = _load_registered_entry_and_type(name, registry_namespace)
    return registered_type

def _expect_registered_type(name: str, expected_type: list[str], registry_namespace: str) -> None:
    registered_type = _load_registered_type(name, registry_namespace)
    if registered_type not in expected_type:
        rlog.error("Checkout config `{}` is registered as `{}`, not `{}`".format(name, registered_type, expected_type))
        fail("checkout config has wrong type")

def _bool_to_checkout_value(value: bool) -> str:
    if value:
        return _ON
    return _OFF

def _register_entry(
        name: str,
        help: str,
        type: str,
        namespace: str = _DEFAULT_REGISTRY_NAMESPACE,
        values = None,
        is_inherit_from_env: bool = False):
    option = _option_new(
        help = help,
        type = type,
        values = values,
        is_inherit_from_env = is_inherit_from_env,
    )

    checkout_modify_value(
        _REGISTRY_ENTRIES,
        modifier = lambda current_entries: _registry_entries_add(current_entries, name, option),
        path = namespace,
    )

def checkout_config_load_registry(registry_namespace = _DEFAULT_REGISTRY_NAMESPACE):
    """
    Loads the checkout config registry.

    Args:
        registry_namespace: namespace of the checkout config registry.

    Returns:
        a dict with the names, types, and help text to use for all registered values.
    """
    return _load_registry_entries(registry_namespace)

def checkout_config_register_optin(
        name: str,
        help: str,
        namespace: str = _DEFAULT_REGISTRY_NAMESPACE,
        is_inherit_from_env: bool = False) -> None:
    """
    Registers an opt-in configuration option.

    Opt-in options load as False unless their stored value is "ON".

    Args:
        name: The configuration option name.
        help: Human-readable description of the configuration option.
        namespace: The checkout store namespace used for registration metadata.
        is_inherit_from_env: When True, missing values are initialized from env `name`,
            falling back to "OFF".

    Returns:
        None.
    """
    _register_entry(
        name,
        help,
        type = _TYPE_OPTIN,
        namespace = namespace,
        is_inherit_from_env = is_inherit_from_env,
    )

def checkout_config_register_optout(
        name: str,
        help: str,
        namespace: str = _DEFAULT_REGISTRY_NAMESPACE,
        is_inherit_from_env: bool = False) -> None:
    _register_entry(
        name,
        help,
        type = _TYPE_OPTOUT,
        namespace = namespace,
        is_inherit_from_env = is_inherit_from_env,
    )

def checkout_config_register_value(
        name: str,
        help: str,
        namespace: str = _DEFAULT_REGISTRY_NAMESPACE) -> None:
    _register_entry(name, help, type = _TYPE_ANY, namespace = namespace)

def _validate_enum_values(name: str, values: list[dict]) -> None:
    if len(values) == 0:
        rlog.error("Checkout enum config `{}` must register at least one enum value".format(name))
        fail("checkout config enum has invalid values")

    for idx, enum_value in enumerate(values):
        if _ENUM_ENTRY_VALUE not in enum_value:
            rlog.error("Checkout enum config `{}` has value entry at index `{}` without `value`".format(name, idx))
            fail("checkout config enum has invalid values")

        if _ENUM_ENTRY_HELP not in enum_value:
            rlog.error("Checkout enum config `{}` has value entry `{}` without `help`".format(name, enum_value.get(_ENUM_ENTRY_VALUE)))
            fail("checkout config enum has invalid values")

def _load_registered_enum_values(name: str, registered_entry: dict):
    registered_values = registered_entry.get(_VALUES)
    if registered_values == None:
        rlog.error("Checkout enum config `{}` has no registered values".format(name))
        fail("checkout config enum has no values")

    if type(registered_values) != "list":
        rlog.error("Checkout enum config `{}` has invalid registered `values` type `{}`; expected `list`".format(name, type(registered_values)))
        fail("checkout config enum has invalid values")

    enum_values = []
    for idx, enum_value in enumerate(registered_values):
        if type(enum_value) != "dict":
            rlog.error("Checkout enum config `{}` has non-dict value entry at index `{}` (type `{}`)".format(name, idx, type(enum_value)))
            fail("checkout config enum has invalid values")

        if _ENUM_ENTRY_VALUE not in enum_value:
            rlog.error("Checkout enum config `{}` has registered entry without `value`: `{}`".format(name, enum_value))
            fail("checkout config enum has invalid values")

        if _ENUM_ENTRY_HELP not in enum_value:
            rlog.error("Checkout enum config `{}` has registered entry without `help`: `{}`".format(name, enum_value))
            fail("checkout config enum has invalid values")

        enum_entry_value = enum_value.get(_ENUM_ENTRY_VALUE)
        if type(enum_entry_value) != "string":
            rlog.error("Checkout enum config `{}` has non-string enum `value` at index `{}` (type `{}`)".format(name, idx, type(enum_entry_value)))
            fail("checkout config enum has invalid values")

        enum_values.append(enum_entry_value)

    if len(enum_values) == 0:
        rlog.error("Checkout enum config `{}` has no registered enum values".format(name))
        fail("checkout config enum has no values")

    return enum_values

def _is_inherit_from_env(name: str, registered_entry: dict) -> bool:
    is_inherit_from_env = registered_entry.get(_IS_INHERIT_FROM_ENV_KEY)
    if is_inherit_from_env == None:
        return False

    if is_inherit_from_env != True and is_inherit_from_env != False:
        rlog.error("Checkout config `{}` has invalid `is_inherit_from_env` value `{}`".format(name, is_inherit_from_env))
        fail("checkout config has invalid inherit_from_env")

    return is_inherit_from_env

def _default_stored_value_for_type(
        name: str,
        registered_type: str,
        registered_entry: dict):
    if registered_type == _TYPE_OPTIN:
        return _OFF

    if registered_type == _TYPE_OPTOUT:
        return _ON

    if registered_type == _TYPE_ENUM:
        enum_values = _load_registered_enum_values(name, registered_entry)
        return enum_values[0]

    rlog.error("Checkout config `{}` type `{}` does not support env inheritance".format(name, registered_type))
    fail("checkout config type does not support env inheritance")

def _load_stored_value(
        name: str,
        namespace: str,
        registered_type: str,
        registered_entry: dict):
    """
    Loads a stored value, applying env inheritance when enabled and missing.

    Args:
        name: The configuration option name.
        namespace: The checkout store namespace containing stored option values.
        registered_type: Registered configuration type.
        registered_entry: Registered option metadata.

    Returns:
        The stored value or None when not set and inheritance is disabled.
    """
    value = workspace_load_value(name, namespace)
    if value != None:
        return value

    if not _is_inherit_from_env(name, registered_entry):
        if registered_type == _TYPE_OPTIN:
            return _OFF

        if registered_type == _TYPE_OPTOUT:
            return _ON

        return None

    default_value = _default_stored_value_for_type(name, registered_type, registered_entry)
    checkout_store_env_or(name, env = name, other = default_value, path = namespace)
    return workspace_load_value(name, namespace)

def checkout_config_new_enum_entry(value: str, help: str | None = None) -> dict:
    """
    Creates a new enum entry that can be passed to `checkout_config_register_enum(values[<return value>])`

    Args:
        value: The value of the enum
        help: The optional help text for this enum value.
    """
    return {
        _ENUM_ENTRY_VALUE: value,
        _ENUM_ENTRY_HELP: help,
    }

def checkout_config_register_enum(
        name: str,
        help: str,
        values: list[dict],
        namespace: str = _DEFAULT_REGISTRY_NAMESPACE,
        is_inherit_from_env: bool = False) -> None:
    """
    Registers an enum configuration option.

    Args:
        name: The enum configuration name.
        help: Help string for the enum configuration
        values: Use the return value of checkout_config_new_enum_entry().
        namespace: The checkout store namespace used for registration metadata.
        is_inherit_from_env: When True, missing values are initialized from env `name`,
            falling back to the first registered enum value.

    Returns:
        None.
    """
    _validate_enum_values(name, values)
    _register_entry(
        name,
        help,
        type = _TYPE_ENUM,
        namespace = namespace,
        values = values,
        is_inherit_from_env = is_inherit_from_env,
    )

def checkout_config_store_option(
        name: str,
        value: bool,
        namespace: str = _DEFAULT_NAMESPACE) -> None:
    """
    Stores a bool for a registered opt-in or opt-out configuration option.

    Args:
        name: The configuration option name.
        value: The boolean value to store as "ON" or "OFF".
        namespace: The checkout store namespace used for stored option values.

    Returns:
        None.
    """
    checkout_store_value(name, value = _bool_to_checkout_value(value), path = namespace)

def checkout_config_store_value(
        name: str,
        value,
        namespace: str = _DEFAULT_NAMESPACE) -> None:
    """
    Stores any value for a registered any configuration option.

    Args:
        name: The configuration option name.
        value: The value to store. Can be any checkout-store-serializable value.
        namespace: The checkout store namespace used for stored values.

    Returns:
        None.
    """
    checkout_store_value(name, value = value, path = namespace)

def checkout_config_store_enum(
        name: str,
        value: str,
        namespace: str = _DEFAULT_NAMESPACE):
    """
    Stores a value for an enum configuration option.

    No registration validation is performed here because enum values may be
    persisted before registration metadata exists.

    Args:
        name: The configuration option name.
        value: The enum value to store.
        namespace: The checkout store namespace used for stored option values.

    Returns:
        None.
    """
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
        For opt-in options, True only when the stored value is "ON". For opt-out options, False only when the stored value is "OFF". For enum and any options, the stored value or None when no value is stored.
    """

    registered_entry, registered_type = _load_registered_entry_and_type(name, registry_namespace)
    value = _load_stored_value(name, namespace, registered_type, registered_entry)

    if registered_type == _TYPE_OPTIN:
        return value == _ON

    if registered_type == _TYPE_OPTOUT:
        return value != _OFF

    if registered_type == _TYPE_ENUM:
        enum_values = _load_registered_enum_values(name, registered_entry)
        if value != None and value not in enum_values:
            rlog.error("Checkout enum config `{}` has invalid stored value `{}`; expected one of `{}`".format(name, value, enum_values))
            fail("checkout config enum has invalid stored value")

    return value

def checkout_config_load_value(
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
    _expect_registered_type(name, [_TYPE_ANY], registry_namespace)
    return workspace_load_value(name, namespace)

def checkout_config_load_enum(
        name: str,
        namespace: str = _DEFAULT_NAMESPACE,
        registry_namespace: str = _DEFAULT_REGISTRY_NAMESPACE):
    """
    Loads an enum configuration option.

    Args:
        name: The configuration option name.
        namespace: The checkout store namespace containing stored option values.
        registry_namespace: The checkout store namespace containing registered options.

    Returns:
        The stored enum value, or None when no value is stored.
    """
    registered_entry, registered_type = _load_registered_entry_and_type(name, registry_namespace)
    if registered_type != _TYPE_ENUM:
        rlog.error("Checkout config `{}` is registered as `{}`, not `{}`".format(name, registered_type, [_TYPE_ENUM]))
        fail("checkout config has wrong type")

    enum_values = _load_registered_enum_values(name, registered_entry)
    result = _load_stored_value(name, namespace, registered_type, registered_entry)

    if result != None and result not in enum_values:
        rlog.error("Checkout enum config `{}` has invalid stored value `{}`; expected one of `{}`".format(name, result, enum_values))
        fail("checkout config enum has invalid stored value")

    return result

def checkout_config_load_values(
        namespace = _DEFAULT_NAMESPACE,
        registry_namespace = _DEFAULT_REGISTRY_NAMESPACE) -> dict:
    """
    Reads all the values from the registry.

    Args:
        namespace: namespace for values
        registry_namespace: namespace for registry

    Returns:
        dict containing all registry values. None is set for registry values that are not set.
    """
    values = {}
    registry = checkout_config_load_registry(registry_namespace)
    for name, registry in registry.items():
        registered_entry, registered_type = _load_registered_entry_and_type(name, registry_namespace)
        value = _load_stored_value(name, namespace, registered_type, registered_entry)
        values.update({name: value})

    return values

def checkout_config_add_markdown(
        name: str,
        output = "checkout-config.md",
        namespace = _DEFAULT_NAMESPACE,
        registry_namespace = _DEFAULT_REGISTRY_NAMESPACE):
    rules = rules_new(name, ["export_json", "export_markdown"])
    json_name = "build/{}.json".format(name)
    checkout_update_asset(
        rules_as_rule(rules, "export_json"),
        destination = json_name,
        value = {
            "registry": checkout_config_load_registry(registry_namespace),
            "values": checkout_config_load_values(namespace),
        },
    )

    checkout_add_exec(
        name,
        command = "@star/sdk/script/checkout-config-to-md.exec.star",
        args = [
            "--input=" + json_name,
            "--output=" + output,
        ],
        deps = [rules_as_dep(rules, "export_json")],
    )

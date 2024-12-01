"""
Add sccache to the workspace
"""

load("checkout.star", "checkout_update_asset", "checkout_add_cargo_bin")

def sccache_add(name, version):
    """
    Add sccache to the workspace and to .cargo/config.toml

    Args:
        name (str): The name of the rule.
        version (str): The version of sccache to add.
    """

    checkout_add_cargo_bin(
        "{}_sccache_cargo_bin".format(name),
        crate = "sccache",
        version = version,
        bins = ["sccache"],
    )

    checkout_update_asset(
        "{}_cargo_config".format(rule_name),
        destination = ".cargo/config.toml",
        value = {
            "build": {"rustc-wrapper": "sccache"},
        },
    )

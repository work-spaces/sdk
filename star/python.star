"""
Add Python to your sysroot.
"""

load(
    "checkout.star",
    "checkout_add_platform_archive",
    "checkout_update_asset",
)
load("run.star", "run_add_exec")
load("//@packages/star/github.com/astral-sh/packages.star", "packages")

def python_add_uv(rule_name, uv_version, ruff_version, python_version, packages = []):
    """
    Add Python to your sysroot.

    Args:
        rule_name (str): The name of the rule.
        uv_version (str): uv version from //@packages/star/github.com/astral-sh/uv
        ruff_version (str): ruff version from //@packages/star/github.com/astral-sh/ruff
        python_version (str): The version of Python to install
        packages (list): The Python packages to install
    """

    uv_platforms = packages["uv"][uv_version]
    ruff_platforms = packages["ruff"][ruff_version]

    checkout_add_platform_archive(
        "{}_checkout_uv".format(rule_name),
        platforms = uv_platforms,
    )

    checkout_add_platform_archive(
        "{}_checkout_ruff".format(rule_name),
        platforms = ruff_platforms,
    )

    checkout_update_asset(
        "{}_black_formatter_vs_code".format(rule_name),
        destination = ".vscode/extensions.json",
        value = {
            "recommendations": ["ms-python.python", "ms-python.black-formatter"],
        },
    )

    workspace_path = info.get_absolute_path_to_workspace()
    store_path = info.get_path_to_store()

    checkout_update_asset(
        "{}_update_uv_env".format(rule_name),
        paths = ["{}/venv/bin".format(workspace_path)],
        vars = {
            "VIRTUAL_ENV": "{}/venv".format(workspace_path),
            "UV_TOOL_DIR": "{}/uv".format(store_path),
            "UV_TOOL_BIN_DIR": "{}/uv/bin".format(store_path),
            "UV_PROJECT_ENVIRONMENT": "venv",
            "UV_PYTHON_INSTALL_DIR": "{}/uv/python".format(store_path),
        },
    )

    run_add_exec(
        "{}_install_python".format(rule_name),
        type = "Setup",
        command = "uv",
        args = ["python", "install", "{}".format(python_version)],
    )

    run_add_exec(
        "{}_venv".format(rule_name),
        type = "Setup",
        deps = ["{}_install_python".format(rule_name)],
        command = "uv",
        args = ["venv", "--python={}".format(python_version), "venv"],
    )

    run.add_exec(
        "{}_packages".format(rule_name),
        type = "Setup",
        deps = ["{}_venv".format(rule_name)],
        command = "uv",
        args = ["pip", "install"] + packages,
    )

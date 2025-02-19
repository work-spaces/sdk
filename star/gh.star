"""
Spaces starlark function for archiving and publishing to github using GH
"""

load("run.star", "run_add_exec", "run_add_target")

def gh_add_publish_archive(
        name,
        input,
        version,
        deploy_repo,
        deps,
        suffix = "tar.xz"):
    """Creates an archive and publishes it to github.

    This can be run on multiple OS's and multiple arch's.

    Args:
        name: Name of the project to publish.
        input: The workspace path to the folder/file to archive and publish
        version: Version to publish
        deploy_repo: The github URL to the repo
        deps: dependencies for the archive
        suffix: The suffix of the archive file (tar.gz, tar.xz, tar.bz2, zip)
    """

    PLATFORM = info.get_platform_name()

    ARCHIVE_RULE_NAME = "{}_archive".format(name)
    ARCHIVE_INFO = {
        "input": input,
        "name": name,
        "version": version,
        "driver": suffix,
        "platform": PLATFORM,
    }

    ARCHIVE_OUTPUT_INFO = info.get_build_archive_info(rule_name = ARCHIVE_RULE_NAME, archive = ARCHIVE_INFO)
    ARCHIVE_OUTPUT = ARCHIVE_OUTPUT_INFO["archive_path"]
    ARCHIVE_SHA256 = ARCHIVE_OUTPUT_INFO["sha256_path"]

    run.add_archive(
        rule = {"name": ARCHIVE_RULE_NAME, "deps": deps},
        archive = ARCHIVE_INFO,
    )

    REPO_ARG = "--repo={}".format(deploy_repo)
    ARCHIVE_NAME = "{}-v{}".format(name, version)
    CHECK_RELEASE_RULE_NAME = "{}_check_release".format(name)
    RELEASE_RULE_NAME = "{}_release".format(name)
    PUBLISH_BINARY_RULE_NAME = "{}_publish_release".format(name)
    PUBLISH_SHA256_RULE_NAME = "{}_publish_sha256".format(name)
    GH_COMMAND = "{}/sysroot/bin/gh".format(info.get_path_to_spaces_tools())

    run.add_exec_if(
        rule = {"name": CHECK_RELEASE_RULE_NAME, "deps": [ARCHIVE_RULE_NAME]},
        exec_if = {
            "if": {
                "command": GH_COMMAND,
                "args": [
                    "release",
                    "view",
                    ARCHIVE_NAME,
                    REPO_ARG,
                ],
                "expect": "Failure",
            },
            "then": [RELEASE_RULE_NAME],
        },
    )

    run_add_exec(
        RELEASE_RULE_NAME,
        deps = [CHECK_RELEASE_RULE_NAME],
        type = "Optional",
        command = GH_COMMAND,
        args = [
            "release",
            "create",
            ARCHIVE_NAME,
            "--generate-notes",
            REPO_ARG,
        ],
    )

    run_add_exec(
        PUBLISH_BINARY_RULE_NAME,
        deps = [RELEASE_RULE_NAME],
        command = GH_COMMAND,
        args = [
            "release",
            "upload",
            ARCHIVE_NAME,
            ARCHIVE_OUTPUT,
            REPO_ARG,
        ],
    )

    run_add_exec(
        PUBLISH_SHA256_RULE_NAME,
        deps = [RELEASE_RULE_NAME],
        command = GH_COMMAND,
        args = [
            "release",
            "upload",
            ARCHIVE_NAME,
            ARCHIVE_SHA256,
            REPO_ARG,
        ],
    )

    run_add_target(name, deps = [PUBLISH_BINARY_RULE_NAME, PUBLISH_SHA256_RULE_NAME])

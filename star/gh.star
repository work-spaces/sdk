"""
Spaces starlark function for archiving and publishing to github using GH
"""

load("info.star", "info_get_platform_name")
load("run.star", "run_add_exec", "run_add_target")
load("shell.star", "shell")
load("ws.star", "workspace_get_build_archive_info")

def gh_add_publish_archive(
        name,
        input,
        version,
        deploy_repo,
        deps,
        sh = "bash",
        suffix = "tar.xz"):
    """Creates an archive and publishes it to github.

    This can be run on multiple OS's and multiple arch's.

    Args:
        name: Name of the project to publish.
        input: The workspace path to the folder/file to archive and publish
        version: Version to publish
        deploy_repo: The github URL to the repo
        deps: dependencies for the archive
        sh: The shell to use for running commands (default: bash)
        suffix: The suffix of the archive file (tar.gz, tar.xz, tar.bz2, zip)
    """

    PLATFORM = info_get_platform_name()

    ARCHIVE_RULE_NAME = "{}_archive".format(name)
    ARCHIVE_INFO = {
        "input": input,
        "name": name,
        "version": version,
        "driver": suffix,
        "platform": PLATFORM,
    }

    ARCHIVE_OUTPUT_INFO = workspace_get_build_archive_info(ARCHIVE_RULE_NAME, archive = ARCHIVE_INFO)
    ARCHIVE_OUTPUT = ARCHIVE_OUTPUT_INFO["archive_path"]
    ARCHIVE_SHA256 = ARCHIVE_OUTPUT_INFO["sha256_path"]

    run.add_archive(
        rule = {"name": ARCHIVE_RULE_NAME, "deps": deps},
        archive = ARCHIVE_INFO,
    )

    REPO_ARG = "--repo={}".format(deploy_repo)
    ARCHIVE_NAME = "{}-v{}".format(name, version)
    RELEASE_RULE_NAME = "{}_release".format(name)
    PUBLISH_BINARY_RULE_NAME = "{}_publish_release".format(name)
    PUBLISH_SHA256_RULE_NAME = "{}_publish_sha256".format(name)
    GH_COMMAND = "{}/sysroot/bin/gh".format(info.get_path_to_spaces_tools())

    CHECK_RELEASE_COMMAND = "{} release view {} {}".format(
        GH_COMMAND,
        ARCHIVE_NAME,
        REPO_ARG,
    )

    CREATE_RELEASE_COMMAND = "{} release create {} --generate-notes {}".format(
        GH_COMMAND,
        ARCHIVE_NAME,
        REPO_ARG,
    )

    shell(
        RELEASE_RULE_NAME,
        script = "{} || {}".format(
            CHECK_RELEASE_COMMAND,
            CREATE_RELEASE_COMMAND,
        ),
        shell = sh,
        deps = [ARCHIVE_RULE_NAME],
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

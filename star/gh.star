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

    platform = info.get_platform_name()

    archive_rule_name = "{}_archive".format(name)
    archive_info = {
        "input": input,
        "name": name,
        "version": version,
        "driver": suffix,
        "platform": platform,
    }

    archive_output_info = info.get_build_archive_info(rule_name = archive_rule_name, archive = archive_info)
    archive_output = archive_output_info["archive_path"]
    archive_sha256 = archive_output_info["sha256_path"]

    run.add_archive(
        rule = {"name": archive_rule_name, "deps": deps},
        archive = archive_info,
    )

    repo_arg = "--repo={}".format(deploy_repo)
    archive_name = "{}-v{}".format(name, version)
    check_release_rule_name = "{}_check_release".format(name)
    release_rule_name = "{}_release".format(name)
    publish_binary_rule_name = "{}_publish_release".format(name)
    publish_sha256_rule_name = "{}_publish_sha256".format(name)
    gh_command = "{}/sysroot/bin/gh".format(info.get_path_to_spaces_tools())

    run.add_exec_if(
        rule = {"name": check_release_rule_name, "deps": [archive_rule_name]},
        exec_if = {
            "if": {
                "command": gh_command,
                "args": [
                    "release",
                    "view",
                    archive_name,
                    repo_arg,
                ],
                "expect": "Failure",
            },
            "then": [release_rule_name],
        },
    )

    run_add_exec(
        release_rule_name,
        deps = [check_release_rule_name],
        type = "Optional",
        command = gh_command,
        args = [
            "release",
            "create",
            archive_name,
            "--generate-notes",
            repo_arg,
        ],
    )

    run_add_exec(
        publish_binary_rule_name,
        deps = [release_rule_name],
        command = gh_command,
        args = [
            "release",
            "upload",
            archive_name,
            archive_output,
            repo_arg,
        ],
    )

    run_add_exec(
        publish_sha256_rule_name,
        deps = [release_rule_name],
        command = gh_command,
        args = [
            "release",
            "upload",
            archive_name,
            archive_sha256,
            repo_arg,
        ],
    )

    run_add_target(name, deps = [publish_binary_rule_name, publish_sha256_rule_name])

"""
Spaces starlark function for archiving and publishing to github using GH
"""

load("run.star", "run_add_exec")
load("checkout.star", "checkout_add_platform_archive")
load("//@packages/star/github.com/cli/cli/packages.star", "packages")

def gh_add(name, version):
    """
    Adds the gh executable to the sysroot.

    Args:
        name: name of the rule to checkout gh (can be anything)
        version: The version of the release found in @packages/star/github.com/cli/cli
    """

    checkout_add_platform_archive(
        name = name,
        platforms = packages[version]["platforms"],
    )

def gh_add_publish_archive(name, input, version, deploy_repo, deps, suffix = "tar.xz"):
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

    archive_info = info.get_build_archive_info(rule_name = archive_rule_name, archive = archive_info)
    archive_output = archive_info["archive_path"]
    archive_sha256 = archive_info["sha256_path"]

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

    run.add_exec_if(
        rule = {"name": check_release_rule_name, "deps": [archive_rule_name]},
        exec_if = {
            "if": {
                "command": "gh",
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
        command = "gh",
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
        command = "gh",
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
        command = "gh",
        args = [
            "release",
            "upload",
            archive_name,
            archive_sha256,
            repo_arg,
        ],
    )

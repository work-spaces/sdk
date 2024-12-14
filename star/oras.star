"""
Spaces starlark functions for publishing packages using oras
"""

load("run.star", "run_add_exec", "run_add_target")

def oras_add_publish_archive(
    name, domain, owner, input, version, deps, suffix = "tar.xz"):
    """
    Publishes an archive using oras.

    Args:
        name: Name of the project to publish.
        domain: The domain of the project.
        owner: The owner of the project.
        input: The workspace path to the folder/file to archive and publish
        version: Version to publish
        deps: dependencies for the archive
        suffix: The suffix of the archive file (tar.gz, tar.xz, tar.bz2, zip)
    """

    platform = info.get_platform_name()

    archive_rule_name = "{}_archive".format(name)
    oras_rule_push_name = "{}_oras_push".format(name)
    archive_info = {
        "input": input,
        "name": name,
        "version": version,
        "driver": suffix,
        "platform": platform,
    }

    archive_output_info = info.get_build_archive_info(rule_name = archive_rule_name, archive = archive_info)
    archive_output = archive_output_info["archive_path"]

    run.add_archive(
        rule = {"name": archive_rule_name, "deps": deps},
        archive = archive_info,
    )

    oras_name = "{}-{}".format(name, platform)
    oras_address = "{}/{}/{}:{}".format(domain, owner, oras_name, version)

    oras_artifact = "{}:application/vnd.unknown.layer.{}+{}".format(archive_output, version, suffix)

    oras_command = "{}/sysroot/bin/oras".format(info.get_path_to_spaces_tools())

    run_add_exec(
        oras_rule_push_name,
        command = oras_command,
        args = [
            "push",
            oras_address,
            oras_artifact,
        ],
        deps = [
            archive_output,
        ],
    )

    run_add_target(name, deps = [oras_rule_push_name])

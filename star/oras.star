"""
Spaces starlark functions for publishing packages using oras
"""

load("run.star", "run_add_exec", "run_add_target")
load("checkout.star", "checkout_add_platform_archive")


def _get_oras_command():
    return "{}/sysroot/bin/oras".format(info.get_path_to_spaces_tools())

def _get_oras_label(domain, owner, name, version):
    platform = info.get_platform_name()
    oras_name = "{}-{}".format(name, platform)
    return "{}/{}/{}:{}".format(domain, owner, oras_name, version)


def oras_add_publish_archive(
        name,
        domain,
        owner,
        version,
        input,
        deps,
        suffix = "tar.xz"):
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

    oras_label = _get_oras_label(domain, owner, name, version)

    # split archive_output between parent folder and file name
    archive_output_folder = archive_output.rsplit("/", 1)[0]
    archive_output_file = archive_output.rsplit("/", 1)[1]
    oras_artifact = "{}:application/vnd.unknown.layer.{}+{}".format(archive_output_file, version, suffix)

    oras_command = _get_oras_command()
    run_add_exec(
        oras_rule_push_name,
        command = oras_command,
        args = [
            "push",
            oras_label,
            oras_artifact,
        ],
        deps = [
            archive_rule_name,
        ],
        working_directory = archive_output_folder,
    )

    run_add_target(name, deps = [oras_rule_push_name])

def oras_checkout_archive(
        name,
        domain,
        owner,
        version,
        add_prefix = "sysroot"):
    """
    Checks out an archive using oras.

    Args:
        name: Name of the project to publish.
        domain: The domain of the project.
        owner: The owner of the project.
        version: Version to publish
        add_prefix: prefix of where to install the archive
        deps: dependencies for the archive
    """

    url = "oras://{}".format(_get_oras_label(domain, owner, name, version))
    platform = info.get_platform_name()

    checkout_add_platform_archive(
        name,
        platforms = {
            platform : {
                "url": url,
                "sha256": "{}:/layers/0/digest:/layers/0/annotations/org.opencontainers.image.title".format(url),
                "link": "Hard",
                "add_prefix": add_prefix,
            }
        }
    )

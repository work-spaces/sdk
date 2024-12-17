"""
Spaces starlark functions for publishing packages using oras
"""

load("run.star", "run_add_exec", "run_add_target")
load("checkout.star", "checkout_add_oras_archive")

def _get_oras_command():
    return "{}/sysroot/bin/oras".format(info.get_path_to_spaces_tools())

def _get_oras_label(url, artifact, tag):
    return "{}/{}:{}".format(url, artifact, tag)

def oras_add_publish_archive(
        name,
        url,
        artifact,
        tag,
        input,
        deps,
        deploy_repo = None,
        layer_info = "application/archive",
        suffix = "tar.xz"):
    """
    Publishes an archive using oras.

    Args:
        name: Name of the project to publish.
        url: The URL of the oras archive to publish.
        artifact: The artifact name of the oras archive.
        tag: The tag of the oras archive.
        input: The workspace path to the folder/file to archive and publish.
        deps: Dependencies for the archive.
        deploy_repo: The deploy repository to publish the archive to.
        layer_info: The layer info of the archive.
        suffix: The suffix of the archive file (tar.gz, tar.xz, tar.bz2, zip).
    """

    platform = info.get_platform_name()

    archive_rule_name = "{}_archive".format(name)
    oras_rule_push_name = "{}_oras_push".format(name)

    archive_info = {
        "input": input,
        "name": artifact,
        "version": tag,
        "driver": suffix,
        "platform": platform,
    }

    archive_output_info = info.get_build_archive_info(rule_name = archive_rule_name, archive = archive_info)
    archive_output = archive_output_info["archive_path"]
    run.add_archive(
        rule = {"name": archive_rule_name, "deps": deps},
        archive = archive_info,
    )

    oras_url_label = _get_oras_label(url, artifact, tag)

    # split archive_output between parent folder and file name
    archive_output_folder = archive_output.rsplit("/", 1)[0]
    archive_output_file = archive_output.rsplit("/", 1)[1]
    artifact_type = "{}+{}".format(layer_info, suffix)

    oras_command = _get_oras_command()

    deploy_args = [] if deploy_repo == None else ['--annotation="org.opencontainers.image.source={}'.format(deploy_repo)]

    run_add_exec(
        oras_rule_push_name,
        command = oras_command,
        args = [
            "push",
            "--artifact-type={}".format(artifact_type),
        ] + deploy_args + [
            oras_url_label,
            archive_output_file,
        ],
        deps = [
            archive_rule_name,
        ],
        working_directory = archive_output_folder,
    )

    run_add_target(name, deps = [oras_rule_push_name])

def oras_add_platform_archive(
        name,
        url,
        artifact,
        tag,
        add_prefix = "sysroot",
        strip_prefix = None,
        globs = None):
    """
    Checks out an archive using oras.

    Args:
        name: Name of the rule.
        url: The URL of the oras archive to download.
        artifact: The artifact name of the oras archive (platform will be appended to artifact name)
        tag: The tag of the oras archive.
        add_prefix: The prefix to add to the archive.
        strip_prefix: The prefix to strip from the archive.
        globs: List of globs to include/exclude.

    """

    url = "oras://{}".format(_get_oras_label(url, name, tag))
    platform = info.get_platform_name()
    effective_artifact = "{}-{}".format(artifact, platform)

    checkout_add_oras_archive(
        name,
        url = url,
        artifact = effective_artifact,
        tag = tag,
        add_prefix = add_prefix,
        strip_prefix = strip_prefix,
        globs = globs,
    )

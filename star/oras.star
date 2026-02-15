"""
Spaces starlark functions for publishing packages using oras
"""

load("checkout.star", "checkout_add_oras_archive")
load("run.star", "run_add_exec", "run_add_target")
load("ws.star", "WORKSPACE_SYSROOT")

def _get_oras_command():
    return "{}/sysroot/bin/oras".format(info.get_path_to_spaces_tools())

def _get_oras_label(url, artifact, tag):
    return "{}/{}:{}".format(url, artifact.lower(), tag)

def oras_add_publish_archive(
        name,
        url,
        artifact,
        tag,
        input,
        deps,
        deploy_repo = None,
        layer_info = "application/archive",
        suffix = "tar.xz",
        visibility = None):
    """
    Publishes an archive using oras.

    Args:
        name: `str` Name of the project to publish.
        url: `str` The URL of the oras archive to publish.
        artifact: `str` The artifact name of the oras archive.
        tag: `str` The tag of the oras archive.
        input: `str` The workspace path to the folder/file to archive and publish.
        deps: `[str]` Dependencies for the archive.
        deploy_repo: `str` The deploy repository to publish the archive to.
        layer_info: `str` The layer info of the archive.
        suffix: `str` The suffix of the archive file (tar.gz, tar.xz, tar.bz2, zip).
        visibility: `str|[str]` Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.
    """

    PLATFORM = info.get_platform_name()

    ARCHIVE_RULE_NAME = "{}_archive".format(name)
    ORAS_RULE_PUSH_NAME = "{}_oras_push".format(name)

    ARCHIVE_INFO = {
        "input": input,
        "name": artifact,
        "version": tag,
        "driver": suffix,
        "platform": PLATFORM,
    }

    ARCHIVE_OUTPUT_INFO = workspace.get_build_archive_info(rule_name = ARCHIVE_RULE_NAME, archive = ARCHIVE_INFO)
    ARCHIVE_OUTPUT = ARCHIVE_OUTPUT_INFO["archive_path"]
    run.add_archive(
        rule = {"name": ARCHIVE_RULE_NAME, "deps": deps},
        archive = ARCHIVE_INFO,
    )

    ORAS_URL_LABEL = _get_oras_label(url, artifact, tag)

    # split ARCHIVE_OUTPUT between parent folder and file name
    ARCHIVE_OUTPUT_FOLDER = ARCHIVE_OUTPUT.rsplit("/", 1)[0]
    ARCHIVE_OUTPUT_FILE = ARCHIVE_OUTPUT.rsplit("/", 1)[1]
    ARTIFACT_TYPE = "{}+{}".format(layer_info, suffix)

    ORAS_COMMAND = _get_oras_command()

    DEPLOY_ARGS = [] if deploy_repo == None else ["--annotation=org.opencontainers.image.source={}".format(deploy_repo)]

    run_add_exec(
        ORAS_RULE_PUSH_NAME,
        command = ORAS_COMMAND,
        args = [
            "push",
            "--artifact-type={}".format(ARTIFACT_TYPE),
        ] + DEPLOY_ARGS + [
            ORAS_URL_LABEL,
            ARCHIVE_OUTPUT_FILE,
        ],
        deps = [
            ARCHIVE_RULE_NAME,
        ],
        working_directory = "//{}".format(ARCHIVE_OUTPUT_FOLDER),
        visibility = visibility,
    )

    run_add_target(
        name,
        deps = [ORAS_RULE_PUSH_NAME],
        help = "Publish {} using oras".format(name),
        visibility = visibility,
    )

def oras_add_platform_archive(
        name,
        url,
        artifact,
        tag,
        add_prefix = WORKSPACE_SYSROOT,
        globs = None,
        visibility = None):
    """
    Checks out an archive using oras.

    Args:
        name: `str` Name of the rule.
        url: `str` The URL of the oras archive to download.
        artifact: `str` The artifact name of the oras archive (platform will be appended to artifact name)
        tag: `str` The tag of the oras archive.
        add_prefix: `str` The prefix to add to the archive.
        globs: `[str]` List of globs to include/exclude.
        visibility: `str|[str]` Rule visibility: `Public|Private|Rules[]`. See visbility.star for more info.

    """

    PLATFORM = info.get_platform_name()
    EFFECTIVE_ARTIFACT = "{}-{}".format(artifact, PLATFORM)

    checkout_add_oras_archive(
        name,
        url = url,
        artifact = EFFECTIVE_ARTIFACT,
        tag = tag,
        add_prefix = add_prefix,
        globs = globs,
        visibility = visibility,
    )

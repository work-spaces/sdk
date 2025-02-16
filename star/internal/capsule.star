"""
Internal capsule management functions.
"""

_DOMAIN = "domain"
_OWNER = "owner"
_REPO = "repo"

_DESCRIPTOR = "descriptor"
_OPTIONS = "options"

INTERNAL_CAPSULE_OPTION_INSTALL_PATH = "install_path"
INTERNAL_CAPSULE_OPTION_IS_USE_SOURCE = "is_use_source"
INTERNAL_CAPSULE_OPTION_ORAS_URL = "oras_url"
INTERNAL_CAPSULE_OPTION_GH_DEPLOY_REPO = "gh_deploy_repo"
INTERNAL_CAPSULE_OPTION_RELEASE_VERSION = "release_version"
INTERNAL_CAPSULE_OPTION_SOURCE_REVISION = "source_revision"
INTERNAL_CAPSULE_OPTION_ARCHIVE_SUFFIX = "archive_suffix"

def internal_capsule_create_descriptor(
        domain,
        owner,
        repo):
    return {
        _DOMAIN: domain,
        _OWNER: owner,
        _REPO: repo,
    }

def internal_capsule_create_options(
        version,
        source_revision = None,
        archive_suffix = "tar.xz",
        install_path = None,
        oras_url = None,
        gh_deploy_repo = None,
        is_use_source = False):
    EFFECTIVE_SOURCE_REVISION = source_revision if source_revision != None else "v{}".format(release_version)
    return {
        INTERNAL_CAPSULE_OPTION_RELEASE_VERSION: version,
        INTERNAL_CAPSULE_OPTION_SOURCE_REVISION: EFFECTIVE_SOURCE_REVISION,
        INTERNAL_CAPSULE_OPTION_IS_USE_SOURCE: is_use_source,
        INTERNAL_CAPSULE_OPTION_INSTALL_PATH: install_path,
        INTERNAL_CAPSULE_OPTION_ORAS_URL: oras_url,
        INTERNAL_CAPSULE_OPTION_GH_DEPLOY_REPO: gh_deploy_repo,
        INTERNAL_CAPSULE_OPTION_ARCHIVE_SUFFIX: archive_suffix,
    }

def internal_capsule_create(
        capsule,
        options):
    return {
        _DESCRIPTOR: capsule,
        _OPTIONS: options,
    }

def internal_capsule_get_option(
        capsule,
        option):
    return capsule[_OPTIONS][option]


def internal_capsule_to_url(capsule):
    DESCRIPTOR = capsule[_DESCRIPTOR]
    return "https://{}/{}/{}".format(
        DESCRIPTOR[_DOMAIN],
        DESCRIPTOR[_OWNER],
        DESCRIPTOR[_REPO],
    )

def internal_capsule_to_worspace_path(capsule):
    DESCRIPTOR = capsule[_DESCRIPTOR]
    return "{}/{}/{}".format(
        DESCRIPTOR[_DOMAIN],
        DESCRIPTOR[_OWNER],
        DESCRIPTOR[_REPO],
    )

def internal_capsule_to_name(capsule):
    DEV_MARK = "" if info.is_workspace_reproducible() else "-non-reproducible"
    DESCRIPTOR = capsule[_DESCRIPTOR]
    return "{}-{}-{}{}".format(
        DESCRIPTOR[_DOMAIN],
        DESCRIPTOR[_OWNER],
        DESCRIPTOR[_REPO],
        DEV_MARK,
    )

def internal_capsule_to_rule_name(capsule, suffix):
    return "{}_{}".format(internal_capsule_to_name(capsule), suffix)

def internal_capsule_to_oras_artifact(capsule):
    capsule_name = _descriptor_to_name(capsule)
    return "{}-{}".format(capsule_name, info.get_platform_name())

def internal_capsule_to_oras_label(capsule):
    ORAS_ARTIFACT = internal_capsule_to_oras_artifact(capsule)
    URL = internal_capsule_get_option(capsule, INTERNAL_CAPSULE_OPTION_ORAS_URL)
    #oras_label = "{}:{}".format(_descriptor_to_oras_label(url, capsule), "{}-{}".format(version, digest))
    return "{}/{}".format(URL, ORAS_ARTIFACT)
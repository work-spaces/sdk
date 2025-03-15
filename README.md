# Spaces Starlark SDK

This repo contains loadable starlark scripts for writing `spaces` workflows. Most functions are simple wrappers for the `spaces` starlark [built-in functions](https://work-spaces.github.io/docs/builtins/).

## Usage

To use this in your checkout script, use:

```sh
spaces checkout --script=<your-preload-script> --script=<your-checkout-script> --name=<your-workspace-name>
```

`<your-preload-script>` cannot use the `load()` statement because the workspace is empty when it is evaluated. It must call built-ins directly.

```python
# Preload Script
checkout.add_repo(
    rule = {"name": "@star/sdk"},
    repo = {
        "url": "https://github.com/work-spaces/sdk",
        "rev": "v0.3.6",
        "checkout": "Revision",
        "clone": "Default"
    }
)
```

`<your-checkout-script>` can use artifacts checked out in the workspace by the preload script or any script preceeding it on the command line.

```python
# Checkout Script
load(
    "//@star/sdk/star/checkout.star",
    "checkout_add_archive",
    "checkout_update_env",
)

VERSION = "16.0.6"
SHA256 = "662f84b9266d54802e82f2b80ba24177af8032c0b5e677b1bb7466f757d1ece6"

checkout_add_archive(
    "llvm-project",
    url = "https://github.com/llvm/llvm-project/archive/refs/tags/llvmorg-{}.zip".format(VERSION),
    sha256 = SHA256,
    strip_prefix = "llvm-project-llvmorg-{}".format(VERSION),
    add_prefix = "llvm-project",
)
```




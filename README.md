# Spaces Starlark SDK

This repo contains loadable starlark scripts for writing `spaces` workflows.

## Usage

To use this in your checkout script, use:

```sh
spaces checkout --script=<your-preload-script> --script=<your-checkout-script> --name=<your-workspace-name>
```

Then `load` code from this repository in your checkout script.

```python

load("//@star/packages/star/github.com/Kitware/CMake/v3.30.5.star", cmake3_platforms = "platforms")
load("//@star/sdk/star/cmake.star", "add_cmake")
load("//@star/packages/star/github.com/ninja-build/ninja/v1.12.1.star", ninja1_platforms = "platforms")

checkout.add_platform_archive(
    rule = {"name": "ninja1"},
    platforms = ninja1_platforms
)

add_cmake(
    "cmake3"
    platforms = cmake3_platforms
)
```




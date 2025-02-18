# Changes

## v0.2.1

- Improve ergonomics of `capsules`
- Update some internals to use `CONSTANTS` in all caps
- Improve `cmake`/`gnu`/`capsules` integration

## v0.2.0

- Add `type` arguments to `checkout` rules - allows for Optional checkout rules that are skipped
- Refactor `capsules` to just use starlark rules

## v0.1.2

- Fix `>` in info rules

## v0.1.1

- Add `info_assert_...()` for workspace versions

## v0.1.0

- Initial release


## Developer Notes

```sh
export VERSION=0.2.1
git tag -a v$VERSION -m "Update version"
git push origin tag v$VERSION
```
# Changes

## v0.3.2

- Add `std/time.star` for spaces v0.14.3
- Remove `info_get_absolute_path_to_workpace()`
- Add script/scan-log-file

## v0.3.1

- Add clone and revision constant values to `checkout.star`

## v0.3.0

- Update to use `spaces-v0.14`
- Better internal compliance with `CONSTANTS` convention
- Move some `info` to `workspace` in accordance with `spaces-v0.14`

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
export VERSION=0.3.2
git tag -a v$VERSION -m "Update version"
git push origin tag v$VERSION
```
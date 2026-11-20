![CapsLT](icons/CapsLT%20preview.jpg)

# CapsLT

Type Lithuanian letters without switching keyboard language.

| Character | Press keys to type it |
|:---------:|-----------------------|
| `ą` | `Caps lock` + `a`<br>`Caps lock` + `1` |
| `č` | `Caps lock` + `c`<br>`Caps lock` + `2` |
| `ę` | `Caps lock` + `e`<br>`Caps lock` + `3` |
| `ė` | `Caps lock` + `w`<br>`Caps lock` + `4` |
| `į` | `Caps lock` + `i`<br>`Caps lock` + `5` |
| `š` | `Caps lock` + `s`<br>`Caps lock` + `6` |
| `ų` | `Caps lock` + `u`<br>`Caps lock` + `7` |
| `ū` | `Caps lock` + `y`<br>`Caps lock` + `8` |
| `ž` | `Caps lock` + `z`<br>`Caps lock` + `=` |

Add `Shift` for uppercase:

* `Caps lock` + `Shift` + `a` = `Ą`

Tap `Caps lock` alone for `Return`, `Escape`, or `Caps lock` (pick in the menu).
The `Globe` (`fn`) key stays free for switching languages.

## Install

1. Download [CapsLT.zip](https://github.com/donatasben/CapsLT/releases/latest/download/CapsLT.zip), unzip it, and move `CapsLT.app` to Applications.
2. Open it. If macOS blocks it: System Settings → Privacy & Security → **Open Anyway** (one time only).
3. Allow it in System Settings → Privacy & Security → **Accessibility**.
4. Click the **Ąž** icon in the menu bar → turn on **Launch at login**.

If CapsLock is changed in System Settings → Keyboard → Keyboard Shortcuts → Modifier Keys, set it back to **Caps Lock**.

After you install a new version, turn the Accessibility permission off and on again.

In password fields, macOS hides the keys from other apps. There, `Caps lock` works only as `Return`, `Escape`, or `Caps lock` (your menu choice), and it does not type Lithuanian letters.

## Build

```sh
./build.sh
```

Output: `build/CapsLT.app` and `build/CapsLT.zip`. Needs Xcode Command Line Tools.

## Release

Push a version tag. GitHub builds the app and makes a release with `CapsLT.zip`.

```sh
git tag v1.0.0 && git push origin v1.0.0
```

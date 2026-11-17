# CapsLT

Type Lithuanian letters without switching keyboard language.

Hold **CapsLock** and press a key:

| Key | a / 1 | c / 2 | e / 3 | w / 4 | i / 5 | s / 6 | u / 7 | y / 8 | z / = |
|-----|-------|-------|-------|-------|-------|-------|-------|-------|-------|
|     | ą     | č     | ę     | ė     | į     | š     | ų     | ū     | ž     |

Hold Shift too for uppercase (Ą, Č…). Tap CapsLock alone for Return, Escape, or Caps Lock (pick in the menu).
The Globe (fn) key stays free for switching languages.

## Install

1. Unzip `CapsLT.zip` and move `CapsLT.app` to Applications.
2. Open it. If macOS blocks it: System Settings → Privacy & Security → **Open Anyway** (one time only).
3. Allow it in System Settings → Privacy & Security → **Accessibility**.
4. Click **Ą** in the menu bar → turn on **Launch at login**.

If CapsLock is changed in System Settings → Keyboard → Keyboard Shortcuts → Modifier Keys, set it back to **Caps Lock**.

After you install a new version, turn the Accessibility permission off and on again.

## Build

```sh
./build.sh
```

Output: `build/CapsLT.app` and `build/CapsLT.zip`. Needs Xcode Command Line Tools.

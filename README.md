# MCTweaks

Adds two things to Mission Control on macOS (Apple Silicon, tested on macOS 27):

- a "×" button on every window: click closes the window, ⌥-click quits the app;
- right-click on a Dock icon shows a menu: the app's windows, Hide, Quit (⌥ → Force Quit), or Open.

## Install from a release

1. Download `MCTweaks-<version>.dmg` from Releases, open it, drag MCTweaks to Applications.
2. The app is not signed with an Apple Developer ID, so macOS blocks the first launch. Run once:
   ```sh
   xattr -dr com.apple.quarantine /Applications/MCTweaks.app
   ```
3. Open MCTweaks and allow it in System Settings → Privacy & Security → Accessibility.
4. To start it at login: System Settings → General → Login Items → add MCTweaks.

## Build from source

```sh
make build              # build/MCTweaks.app
make install            # copy to ~/Applications and start at login (LaunchAgent)
make uninstall
make dmg VERSION=1.2.3  # build/MCTweaks-1.2.3.dmg
swift test
```

## Release

Push a tag: `git tag v0.1.0 && git push origin v0.1.0`. GitHub Actions runs the tests, builds the DMG and creates the release.

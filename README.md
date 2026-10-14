# ZetaReps

> **Status: free, final release, no longer maintained.**
> Version 1.0.4 removed the Premium subscription and the 100-pushup limit; every feature is unlocked for everyone.
> The App Store listing is available until late October 2026, and installed copies keep working after that.
> The source is MIT licensed, so anyone can build or fork it. Website: https://rabah-khalek.github.io/zetareps/

Push-up workout tracker for iPhone. Set-based sessions with rest timers, consistency and intensity
scores, streaks, personal records, progress charts and smart reminders. Everything is stored on the
device with SwiftData: no account, no analytics, no network.

## Download

- App Store (until late October 2026): https://apps.apple.com/app/zetareps/id6754805460

Requires iOS 17 or later.

## Building from source

1. Clone this repository.
2. Open `ZetaReps.xcodeproj` in Xcode 15 or later, pick your team under Signing & Capabilities, and
   run the `ZetaReps` scheme on a simulator or device. `make build` compiles for the simulator from
   the command line.

`DemoDataManager` can fill the app with realistic sample workouts for testing and screenshots.

## How the scores work

- **Consistency (0-10):** workout frequency against the expected days (60%) plus how often the
  target sets and reps were met (40%), over the 3 to 10 most recent workouts.
- **Intensity (0-10):** sets and reps achieved against targets (60%), the 1 to 5 difficulty rating
  (30%) and a bonus for exceeding targets (10%).
- **Streaks** survive a gap of up to two days.

Targets come from a chosen fitness level (Beginner, Intermediate, Advanced) or custom values; the
level recommendations and their sources are listed inside the app under Settings.

## Project layout

- `ZetaReps/` app sources (SwiftUI, SwiftData): `Models/`, `Managers/`, `Views/`
- `ZetaReps.xcodeproj/` Xcode project
- `web/` website, published by the Pages workflow in `.github/workflows/`
- `scripts/` app icon and favicon generators (need Pillow: `pip install pillow`)
- `CHANGELOG.md` release history

## Contributing

The project is not maintained, so issues and pull requests are not monitored. Forks are welcome
under the MIT license.

## License

MIT. See [LICENSE](LICENSE).

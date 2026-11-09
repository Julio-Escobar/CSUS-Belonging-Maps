# P1-264 device accessibility acceptance record

Status: **In progress — not ready to move to Done.**

This record separates verified automated/device evidence from checks that need
a human screen-reader walkthrough. A pending check is not a pass.

## Android environment

| Field | Recorded value |
| --- | --- |
| Device | Android Emulator `sdk gphone64 x86 64` (`emulator-5554`) |
| OS | Android 16 (API 36) |
| App | Fresh debug APK built with `gradlew.bat assembleDebug --no-daemon` |
| TalkBack | `com.google.android.marvin.talkback/.TalkBackService` enabled and bound |
| Accessibility state | Touch exploration enabled; TalkBack reports double-tap handling enabled |

The Android debug build completed successfully. The APK was installed with
`adb install -r` and started as `com.example.belonging_maps_app/.MainActivity`.
TalkBack's notification permission prompt was accepted before the app tree was
captured.

## Android TalkBack flows

| Flow | Verified evidence | Outcome |
| --- | --- | --- |
| Welcome and map selection | With TalkBack enabled, the emulator accessibility tree exposed `Open navigation menu`, `Belonging Maps`, `Belonging Maps logo`, the welcome description, `Campus Maps`, and `Community Maps`. The on-device integration test opened Campus Maps and returned with Back. | **Pending human walkthrough.** The automated tree and integration test do not prove spoken focus order, swipe traversal, or TalkBack double-tap activation. |
| Ummah Browse locations and details | Widget tests cover accessible Browse locations sections, semantic activation, loading/retry, and named items. | **Pending human walkthrough.** No person has yet completed the Ummah location/detail flow with TalkBack speech. |
| Existing admin actions | Widget tests cover named view, edit, delete, login, and logout actions. | **Pending human walkthrough.** No TalkBack user has verified focus order, activation, dialog close, and Back behavior on-device. |

## iOS VoiceOver and Dynamic Type

| Flow | Outcome | Owner / follow-up |
| --- | --- | --- |
| Welcome, map selection, Ummah Browse/details, and admin actions with VoiceOver | **Pending.** This Windows environment has no macOS/Xcode iOS simulator or physical iOS device. | Story assignee: Julio Escobar. Run on an iPhone/iPad or Xcode simulator and record device, iOS version, VoiceOver settings, Dynamic Type 200%, contrast setting, focus order, activation, Back, and close behavior. |

## Automated verification rerun

| Command / scope | Result |
| --- | --- |
| `flutter test --reporter expanded test/admin_actions_accessibility_test.dart` | Passed: 7 tests. |
| `flutter test --reporter expanded test/navigation_accessibility_test.dart test/map_location_browser_test.dart` | Passed: 26 tests. |
| Narrow-screen 200%-text admin layout, edit, details, and delete checks | Passed: 16 tests, including semantic view/edit/delete actions and an in-memory organization-resource API. |
| Full Flutter suite | Passed: 235 tests. |
| `flutter test -d emulator-5554 --reporter expanded integration_test/p1_264_accessibility_flows_test.dart` | Passed: 1 Android integration test (Welcome → Campus Maps → Back). |

## Completion checklist

- [x] Android emulator, current debug APK, and TalkBack configuration recorded.
- [x] Focused Flutter tests rerun after the accessibility-test fixture fixes.
- [x] Android integration test added and passed.
- [ ] A human completes and records the required Android TalkBack spoken walkthrough.
- [ ] A human completes and records the required iOS VoiceOver/Dynamic Type walkthrough.
- [ ] Any failed human check has a linked Jira defect or an identified remediation owner.
- [ ] This record is attached or linked from Jira P1-264 before the story is moved to Done.

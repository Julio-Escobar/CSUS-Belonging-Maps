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

## Human walkthrough scripts

Run each row with the named screen reader enabled. Record the actual spoken
focus order and every pass/fail result before replacing **Pending**. A failed
row needs a linked Jira defect or a remediation owner; unavailable hardware or
software stays pending.

| Platform | Flow and steps | Expected behavior | Actual result | Status |
| --- | --- | --- | --- | --- |
| Android TalkBack | From Welcome, swipe through navigation, branding, description, Campus Maps, and Community Maps. Double-tap Campus Maps, choose a map, use Back, then close any opened panel. | Focus order is meaningful; every named action activates once; Back and Close return to the expected prior screen. | Pending human walkthrough. | Pending |
| Android TalkBack | Open the Ummah map, use Browse locations, swipe through sections and locations, double-tap an item, review its details, then use Back and Close. | Browse labels, location details, Back, and Close are announced and work without focus traps. | Pending human walkthrough. | Pending |
| Android TalkBack | Sign in as an administrator, swipe to named view/edit/delete actions, activate each flow, cancel or close dialogs, then log out. | Controls announce their item and action; dialogs have reachable close/cancel actions; logout clears admin access. | Pending human walkthrough. | Pending |
| iOS VoiceOver | Repeat the Welcome, map selection, Ummah Browse/details, and admin-action flows above with VoiceOver. Repeat key screens at Dynamic Type 200% and with available contrast settings. | The same actions are announced and usable; text remains readable and controls remain reachable at 200%. | Pending: no iOS simulator or device is available in this environment. | Pending |

## Failure handling

For every failed human row, create or link the Jira defect here and name the
remediation owner. Do not change a pending row to passed based only on widget
or integration test output.

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

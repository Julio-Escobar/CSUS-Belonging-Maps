---
name: update-readme
description: Update the root GitHub README.md so it matches the current state of the CSUS Belonging Maps repo (Flutter app, .NET API, setup, tests, CI). Use when asked to update, refresh, or write the README, or after features, endpoints, env variables, or setup steps change.
---

# Update GitHub README

Keep the root `README.md` accurate for new contributors. Every fact in it must come from files in the repo, not from memory or guesses.

## 1. Gather facts

Read these before writing. Skip any that do not exist.

- `mobile/belonging_maps_app/pubspec.yaml`: Flutter/Dart SDK version and key packages (e.g. `arcgis_maps`)
- `mobile/belonging_maps_app/lib/screens/`: list of app screens/features
- `mobile/belonging_maps_app/.env.example`: env variable **names** only
- `backend/BelongingMaps.API/BelongingMaps.API.csproj`: .NET version
- `backend/BelongingMaps.API/Controllers/`: API routes (`[Route]`, `[Http*]` attributes)
- `backend/BelongingMaps.API/Program.cs`: startup behavior (auto-migration, seeding)
- `backend/BelongingMaps.API/Properties/launchSettings.json`: local API URL/port
- `backend/BelongingMaps.API.Tests/` and `mobile/belonging_maps_app/test/`: test setup
- `.github/workflows/ci.yml`: what CI runs and on which branches
- `git log --oneline -20`: recent features worth mentioning

## 2. Write or update these sections

Keep existing content that is still correct. Only change what is outdated or missing.

1. **Title and overview**: what the app is (belonging maps for the SOMOS, Ummah and Ubuntu communities at CSUS) in 2–3 sentences.
2. **Features**: short bullet list based on the screens and endpoints.
3. **Tech stack**: Flutter, ArcGIS Maps SDK, ASP.NET Core, EF Core, SQL Server (Azure).
4. **Project structure**: short tree of `mobile/` and `backend/`.
5. **Getting started**
   - Backend: connection string setup, `dotnet run` from `backend/BelongingMaps.API`, port.
   - Mobile: copy `.env.example` to `.env`, set `API_BASE_URL` (Android emulator `http://10.0.2.2:5162`, iOS simulator `http://localhost:5162`), then `flutter pub get` and `flutter run`.
6. **API endpoints**: table of method, route and purpose, one row per controller action.
7. **Testing**: `flutter test` and `dotnet test backend/backend.sln`, plus what CI runs on pull requests.
8. **Contributing**: branch off `dev`, name branches after Jira tickets (e.g. `P1-252-short-description`), open PRs into `dev`.

## 3. Rules

- **Never** copy values from `.env`, `appsettings.Development.json`, or any secret. Only variable names from `.env.example`.
- Do not invent commands, endpoints or features. If something can't be confirmed from the code, leave it out.
- Use GitHub-flavored Markdown, short sections, and fenced code blocks with a language tag.
- Edit only `README.md`. Do not commit or push. Show a summary of what changed so the user can review it.

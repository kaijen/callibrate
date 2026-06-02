---
id: 1
title: Android-Release-Build reparieren (CI assembleRelease schlägt fehl)
status: review
priority: high
created: 2026-06-01T16:52:37.870206318+02:00
updated: 2026-06-02T14:08:40.991631472+02:00
tags:
    - build
    - ci
    - android
class: standard
---

## Kontext

Der Push des Tags **v1.7.1-beta.1** hat den CI-Release-Workflow ausgelöst;
`flutter build apk --release` (`assembleRelease`) ist fehlgeschlagen.
Fehlgeschlagener Run: GitHub Actions "Release" #26761023987.

## Ursache

Der CI nutzt `subosito/flutter-action@v2` mit `channel: stable` **ohne Versions-Pin**
→ floatet aktuell auf **Flutter 3.44.0**. Diese Version erzwingt Kotlin >= 2.0.
Das Projekt hatte aber ein totes Legacy-`buildscript` mit `kotlin 1.9.22`.
Beim Weiterbauen folgte ein zweiter Fehler: neue transitive AndroidX-Deps
(`androidx.core 1.17.0`, `core-ktx 1.17.0`, `browser 1.9.0`) verlangen AGP >= 8.9.1.

## Bereits erledigt (lokal, UNCOMMITTED, Branch chore/misc-fixes-and-features)

1. android/build.gradle: Legacy-`buildscript`-Block entfernt
   (ext.kotlin_version 1.9.22 + classpath gradle:8.2.2 + kotlin-gradle-plugin).
   → Kotlin-Quelle ist jetzt allein settings.gradle (2.1.0). Kotlin-Fehler verschwand.
2. android/settings.gradle: AGP 8.7.0 -> 8.11.1.
3. android/gradle/wrapper/gradle-wrapper.properties: Gradle 8.10.2 -> 8.14.

## Offen (morgen)

- [ ] Build verifizieren: `/home/kai/flutter/bin/flutter build apk --debug`
      lokal grün bekommen (bestaetigt, dass AGP 8.11.1 + Gradle 8.14 die
      AAR-Metadata-Fehler loest). Achtung: lokales Flutter ist 3.41.4, CI 3.44.0.
      Der Gradle-8.14-Download (~150 MB) macht den ersten Lauf langsam.
- [ ] Optional aber empfohlen: Flutter-Version im CI pinnen
      (.github/workflows/release.yml, flutter-action `flutter-version:`),
      um kuenftiges Floaten von `stable` als Bruchquelle auszuschliessen.
      Tradeoff mit Kai besprechen (Pin vs. immer-aktuell).
- [ ] Android-Gradle-Fixes committen (getrennt vom Lizenz-Commit).
      Pruefen: gradlew, gradle-wrapper.jar, android/app/.cxx/ waren zu
      Session-Beginn UNTRACKED — gehoeren wrapper-Dateien committed?
- [ ] Fehlgeschlagenes Release v1.7.1-beta.1 bereinigen: Tag ist gepusht,
      Release-Workflow rot -> kein APK am GitHub-Release. Nach gemergtem Fix
      entweder Workflow neu starten oder Tag loeschen + neu setzen.
- [ ] PR #97 (Lizenz + Changelog) gegen main ist offen. Entscheiden, ob der
      Gradle-Fix in denselben PR oder einen eigenen geht, bevor neu released wird.

## Verifikation

- `flutter build apk --debug` ohne BUILD FAILED
- Idealerweise `flutter build apk --release` (braucht Keystore: android/app/key.properties)
- Danach: neuer Release-Lauf erzeugt kailibrate-vX.apk am GitHub-Release

## Bewusst ausgelassen

pubspec.lock (modifiziert) und untracked android/-Build-Artefakte sind NICHT Teil
der Aenderungen und blieben aussen vor.

[[2026-06-02]] Tue 12:03
Build verifiziert: flutter build apk --debug erfolgreich (✓ Built app-debug.apk, exit 0). AGP 8.11.1 + Gradle 8.14 loesen die AAR-Metadata-Fehler. .cxx/ zu .gitignore hinzugefuegt.

[[2026-06-02]] Tue 14:08
Build-Fix fertig & gepusht (Commit c5fa3d4) auf chore/misc-fixes-and-features -> PR #97 (mergeable). Debug-Build lokal gruen. Entscheidungen mit Kai: Fix geht in PR #97; Flutter NICHT gepinnt (release.yml unangetastet); Release-Tag v1.7.1-beta.1 raeumt Kai selbst nach Merge auf. OFFEN fuer Kai: (1) PR #97 mergen, (2) danach Tag v1.7.1-beta.1 neu setzen oder Release-Workflow re-runnen, damit das APK am GitHub-Release erscheint.

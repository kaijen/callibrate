# Code generieren (Drift)
gen:
    dart run build_runner build --delete-conflicting-outputs

# Kontinuierlich generieren
gen-watch:
    dart run build_runner watch --delete-conflicting-outputs

test:
    flutter test

lint:
    flutter analyze

apk:
    flutter build apk

release:
    flutter build apk --release

run:
    flutter run

install:
    flutter pub get

clean:
    flutter clean
    dart run build_runner clean

# Release-Tag setzen und pushen (löst CI-Release-Workflow aus)
tag version:
    git tag {{version}}
    git push --tags

# Docs lokal vorschauen (http://127.0.0.1:8000)
docs:
    pip install -r requirements-docs.txt
    mkdocs serve

# Statische Docs nach site/ bauen
docs-build:
    pip install -r requirements-docs.txt
    mkdocs build

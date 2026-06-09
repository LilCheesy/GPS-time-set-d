@echo off
echo Committing MapLibre GL setup...
git add frontflutter/pubspec.yaml frontflutter/pubspec.lock frontflutter/android/app/src/main/AndroidManifest.xml frontflutter/ios/Runner/Info.plist frontflutter/linux/ frontflutter/macos/ frontflutter/web/index.html
git commit -m "chore(flutter): migrate to maplibre_gl and setup native platform configurations"

echo Committing core utilities...
git add frontflutter/lib/core/constants/app_constants.dart frontflutter/lib/core/utils/polyline_decoder.dart
git commit -m "feat(core): add trackasia constants and polyline decoder utility"

echo Committing SOS data models...
git add frontflutter/lib/features/sos/data/models/
git commit -m "feat(sos-data): implement trackasia routing and facility response models"

echo Committing SOS remote datasource...
git add frontflutter/lib/features/sos/data/datasources/sos_remote_datasource.dart
git commit -m "feat(sos-data): implement robust facility search and routing using trackasia api"

echo Committing SOS state providers...
git add frontflutter/lib/shared/providers/location_provider.dart frontflutter/lib/features/sos/presentation/providers/sos_provider.dart
git commit -m "feat(sos-state): add location tracking and sos navigation state management"

echo Committing SOS UI components...
git add frontflutter/lib/shared/widgets/moving_ambulance_icon.dart frontflutter/lib/shared/widgets/navigation_info_panel.dart frontflutter/lib/features/sos/presentation/screens/sos_screen.dart
git commit -m "feat(sos-ui): build interactive map screen with facility selection and navigation"

echo Committing documentation...
git add TRACKASIA_GL_MIGRATION.md
git commit -m "docs: add comprehensive maplibre migration guide"

echo Committing backend configuration...
git add backjavaspring/compose.yaml backjavaspring/src/main/resources/application.properties backjavaspring/fix-postgis.sql
git commit -m "fix(backend): update postgis connection properties and docker configuration"

echo Pushing to GitHub...
git push

echo Done!

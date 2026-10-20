# Digisaka

## Environment setup

This app uses environment variables for configuration that are not stored in the source code or committed to git.

### What the env file is and why it isn't in git
The `env.json` file contains sensitive configuration values like API keys that should never be committed to version control. Instead, we provide an `env.example.json` template that shows the required structure with placeholder values.

### Setup steps
1. Copy `env.example.json` to `env.json`:
   ```bash
   copy mobile\env.example.json mobile\env.json
   ```
2. Edit `mobile/env.json` and replace the placeholder values with your actual API key and base URL:
   ```json
   {
     "API_KEY": "your-actual-api-key-here",
     "API_BASE_URL": "https://your-actual-api-domain.com"
   }
   ```

### Run commands
- Debug mode: `flutter run --dart-define-from-file=env.json`
- Build APK: `flutter build apk --dart-define-from-file=env.json`
- Or press F5 in VS Code using the "Digisaka (dev)" launch configuration

### Important notes
- After changing `env.json` you must do a **full restart** (stop and run again). Hot reload / hot restart will NOT pick up new values.
- The `env.json` file is intentionally excluded from git via `.gitignore` to prevent accidental commits of sensitive data.
- Only commit the `env.example.json` file to share the configuration structure with your team.

### Security note
Any key shipped inside a mobile app can potentially be extracted through reverse engineering. For production applications, consider calling your own backend server and keeping the API key on the server rather than embedding it in the mobile app.
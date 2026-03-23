# EndoAlly iOS — Setup Guide

## 1. Open in Xcode

1. Clone or download this repository so the folder `EndoAlly-iOS/` sits on your Mac.
2. Open **Xcode 15** or later.
3. Choose **File → Open** and select `EndoAlly-iOS/EndoAlly.xcodeproj`.
4. Xcode will automatically resolve the Swift Package Manager dependency (supabase-swift). Wait for the package resolution to finish (bottom status bar shows "Fetching…" then goes quiet).
5. Select the **EndoAlly** scheme and a simulator or connected device from the toolbar, then press **Run (⌘R)**.

---

## 2. Add DM Sans Font Files

The app uses DM Sans (Regular, Medium, SemiBold, Bold). You must add the `.ttf` files manually:

1. Download DM Sans from [Google Fonts](https://fonts.google.com/specimen/DM+Sans) — click **Download family**.
2. Extract the zip. You need these four files from the `static/` folder:
   - `DMSans-Regular.ttf`
   - `DMSans-Medium.ttf`
   - `DMSans-SemiBold.ttf`
   - `DMSans-Bold.ttf`
3. In Xcode's Project Navigator, right-click the **EndoAlly** group (the folder with the blue app icon) and choose **Add Files to "EndoAlly"…**
4. Select all four `.ttf` files. Make sure:
   - **Copy items if needed** is checked.
   - **Add to targets: EndoAlly** is checked.
5. Open `EndoAlly/Info.plist`. Add a new key:
   - Key: `Fonts provided by application` (`UIAppFonts`)
   - Type: Array
   - Add four String items:
     - `DMSans-Regular.ttf`
     - `DMSans-Medium.ttf`
     - `DMSans-SemiBold.ttf`
     - `DMSans-Bold.ttf`
6. Clean the build folder (**⌘⇧K**) and rebuild.

> If you see placeholder system font instead of DM Sans, double-check that the font file names in Info.plist exactly match the filenames on disk (case-sensitive).

---

## 3. Supabase Configuration

### Tables

All tables are already created in the Supabase project (`https://rntneltlfpfybixtbslq.supabase.co`). The full schema lives at `EndoAlly-App/supabase/migration.sql` and includes:

| Table | Purpose |
|---|---|
| `profiles` | User profile (name, age, cycle/period length, last period date, emoji) |
| `symptoms` | Logged symptoms with category, severity, notes, medications, management |
| `checkins` | Daily check-ins (flow, pain, mood, energy, sleep, bowel, notes) |
| `reports` | Generated AI report content and metadata |
| `history_family` | Family history of conditions |
| `history_medications` | Regular medications |
| `history_birth_control` | Birth control history |
| `history_treatments` | Past surgical/medical treatments |
| `history_therapies` | Therapies and exercises |

Row Level Security (RLS) is enabled on all tables with `auth.uid() = user_id` policies — users can only read and write their own rows.

### iOS Deep Link / Redirect URLs

Supabase Auth sends magic links and password-reset emails. For iOS you must register a redirect URL so the app can intercept the link.

1. Go to your Supabase dashboard → **Authentication → URL Configuration**.
2. Under **Redirect URLs**, click **Add URL** and add:
   ```
   endoally://auth/callback
   ```
3. Also update **Site URL** if you haven't already (can be the same `endoally://auth/callback` for a mobile-only project).
4. In Xcode, open the **EndoAlly** target → **Info** tab → **URL Types**. Add a new entry:
   - **Identifier**: `com.endoally.app`
   - **URL Schemes**: `endoally`
5. Handle the incoming URL in `EndoAllyApp.swift` by adding `.onOpenURL` to the `WindowGroup` and passing it to `supabase.auth.session(from:)` if you use magic-link or OAuth flows. (Password-based auth used by default does not require this step.)

---

## 4. Apple Developer Account & TestFlight

### Prerequisites

- An **Apple Developer Program** membership ($99/year) at [developer.apple.com](https://developer.apple.com).
- Your Apple ID added to Xcode under **Xcode → Settings → Accounts**.

### Bundle ID & Certificates

1. Log in to [App Store Connect](https://appstoreconnect.apple.com) and create a new App:
   - **Bundle ID**: `com.endoally.app`
   - **Name**: EndoAlly
   - **Primary language**: English (Australia)
2. In Xcode, select the **EndoAlly** target → **Signing & Capabilities**:
   - Enable **Automatically manage signing**.
   - Set **Team** to your Apple Developer team.
   - Confirm **Bundle Identifier** is `com.endoally.app`.
3. Xcode will automatically create a provisioning profile and signing certificate.

### Build for TestFlight

1. Connect a physical device **or** choose **Any iOS Device (arm64)** from the scheme toolbar.
2. Choose **Product → Archive** (⌘⇧B won't work — use the menu).
3. When the Organizer opens, click **Distribute App → App Store Connect → Upload**.
4. Follow the wizard (keep defaults). Xcode uploads the build to App Store Connect.
5. In App Store Connect → **TestFlight**, add internal testers (up to 100 people with a Developer seat) or external testers (requires a brief Beta App Review).

---

## 5. Add the Anthropic API Key

The AI Assistant and Report generation features require a Claude API key.

1. Get an API key from [console.anthropic.com](https://console.anthropic.com) → **API Keys → Create Key**.
2. Open `EndoAlly/Config.swift` and replace the placeholder:
   ```swift
   static let anthropicAPIKey = "YOUR_ANTHROPIC_API_KEY_HERE"
   ```
   with your actual key:
   ```swift
   static let anthropicAPIKey = "sk-ant-api03-..."
   ```

> **Security note**: Do not commit your API key to a public repository. For production, consider fetching the key from a server-side proxy (similar to the web app's `/api/chat` and `/api/report` routes) so the key is never bundled inside the app binary.

---

## 6. Build and Archive

### Development Build (Simulator or Device)

```
1. Open EndoAlly.xcodeproj in Xcode 15+
2. Select scheme: EndoAlly
3. Select destination: simulator or connected device
4. Press ⌘R to build and run
```

### Production Archive (App Store / TestFlight)

```
1. Select destination: Any iOS Device (arm64)
2. Product → Archive  (⌘⇧B then open Organizer, or use menu)
3. Organizer → select the archive → Distribute App
4. Choose: App Store Connect → Upload
5. Keep defaults on all wizard screens → click Upload
6. Wait ~5 minutes for processing in App Store Connect
7. TestFlight tab → your build will appear under iOS builds
```

### Minimum Requirements

| Requirement | Value |
|---|---|
| Xcode | 15.0 or later |
| iOS Deployment Target | 17.0 |
| Swift | 5.9 |
| supabase-swift | 2.x (resolved automatically via SPM) |
| Anthropic model | `claude-sonnet-4-20250514` |

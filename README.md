<p align="center">
	<img src="assets/readme/banner.svg" alt="Jahiz animated banner" width="100%" />
</p>

<p align="center">
	<img src="https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter" />
	<img src="https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white" alt="Dart" />
	<img src="https://img.shields.io/badge/Firebase-FFCA28?style=flat-square&logo=firebase&logoColor=black" alt="Firebase" />
	<img src="https://img.shields.io/badge/Gemini%20AI-4285F4?style=flat-square&logo=google&logoColor=white" alt="Gemini AI" />
	<img src="https://img.shields.io/badge/Stripe-635BFF?style=flat-square&logo=stripe&logoColor=white" alt="Stripe" />
	<img src="https://img.shields.io/badge/BLoC-5C2D91?style=flat-square&logo=bloc&logoColor=white" alt="BLoC state management" />
</p>

# Jahiz

Jahiz is a Flutter application for AI-assisted interview practice and premium coaching. It combines Gemini-powered question generation, personalized practice sessions, and subscription upgrades backed by Stripe and Firebase.

## Project overview

Jahiz helps candidates practice interviews with daily prompts, structured practice sessions, and detailed feedback. Users can track progress over time, manage their profile, and unlock premium capabilities through subscriptions.

## Features

- AI-generated roles, questions, and evaluations using Gemini.
- Daily question flow with reminders and local notifications.
- Practice sessions with scoring, feedback, and model answers.
- Reports and history with summary metrics.
- Premium subscription flow with Stripe PaymentSheet.
- Firebase authentication with Google sign-in.
- Profile management, onboarding, and theme support.

## Architecture

- Feature-first layout in `lib/features` (auth, home, practice, paywall, notifications, profile).
- Shared core modules in `lib/core` for constants, models, services, theming, and utilities.
- UI-only screens; cubits/services own state, side effects, and data access.
- Premium access enforced by `PremiumAccessGuardService` with paywall routing.
- Reports and history are paginated via `ReportsCubit` and rendered by screens.

## Folder structure

```
lib/
	core/
		constants/
		models/
		services/
		theme/
		utils/
	features/
		auth/
		home/
		notifications/
		onboarding/
		paywall/
		practice/
		profile_management/
		profile_onboarding/
		splash/
assets/
	icon/
	questions/
	splash-screan-icon/
functions/
android/
ios/
web/
windows/
macos/
linux/
```

## Technologies used

- Flutter and Dart
- Firebase Core, Auth, and Firestore
- Google Sign-In
- Stripe PaymentSheet (flutter_stripe)
- flutter_bloc for state management
- Local notifications and time zone scheduling
- flutter_dotenv for environment configuration
- Firebase Cloud Functions (Node.js)

## Setup instructions

### Prerequisites

- Flutter SDK (3.11 or newer)
- Firebase CLI and FlutterFire CLI
- Node.js 24 (for Firebase functions)

### Install dependencies

```bash
flutter pub get
```

### Configure Firebase

1. Create a Firebase project.
2. Run the FlutterFire CLI to generate `lib/firebase_options.dart`.
3. Replace `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` with your project files.

### Configure environment variables

Create a `.env` file in the project root (this file is loaded on startup):

```env
STRIPE_PUBLISHABLE_KEY=pk_test_...
GEMINI_API_KEY=your_primary_key
GEMINI_API_KEYS=optional,key,list
GEMINI_API_KEY_1=optional_key_1
GEMINI_API_KEY_2=optional_key_2
```

### Run the app

```bash
flutter run
```

### Firebase Functions (optional)

```bash
cd functions
npm install
firebase emulators:start --only functions
```

## Environment variables

### App (.env)

| Name | Required | Description |
| --- | --- | --- |
| STRIPE_PUBLISHABLE_KEY | Yes | Stripe publishable key used by PaymentSheet. |
| GEMINI_API_KEY | Yes (for AI features) | Primary Gemini API key. |
| GEMINI_API_KEYS | No | Comma/semicolon-separated keys for rotation. |
| GEMINI_API_KEY_1..N | No | Numbered keys for rotation priority. |

### Firebase Functions secrets

| Name | Required | Description |
| --- | --- | --- |
| STRIPE_SECRET_KEY | Yes | Secret key used by Stripe backend and callables. |

Set the secret via Firebase CLI:

```bash
firebase functions:secrets:set STRIPE_SECRET_KEY
```

## API configuration

### Gemini API

- Used for role suggestions, practice questions, and evaluation feedback.
- Configure with `GEMINI_API_KEY` or `GEMINI_API_KEYS` in `.env`.
- You can also pass keys at build time:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key
```

### Stripe

- Client uses `STRIPE_PUBLISHABLE_KEY` from `.env`.
- Backend secrets must be stored as Firebase Functions secrets.
- Ensure Android themes remain AppCompat/MaterialComponents for Stripe compatibility.

### Payment backend

- Payment intent creation is handled by the payment endpoint configured in `PaymentService`.
- Update the endpoint to point to your own backend or Cloud Functions.

## Usage examples

### Run with a specific Gemini key

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key
```

### Run with multiple Gemini keys (rotation)

```bash
flutter run --dart-define=GEMINI_API_KEYS=key1,key2,key3
```

## Experience preview

Explore the main user journey and core platform capabilities.

```
+------------------+     +---------------------+     +--------------------+
| Onboarding       | --> | Practice Session    | --> | Reports & Insights |
| role/level/stack |     | AI feedback + score |     | averages + history |
+------------------+     +---------------------+     +--------------------+
					 |                                |
					 v                                v
+------------------+               +------------------------+
| Paywall / Premium|               | Profile & Preferences  |
| upgrade options  |               | theme + notifications  |
+------------------+               +------------------------+
```

<table>
	<tr>
		<td width="33%"><strong>AI Practice Engine</strong><br/>Role-aware questions, evaluations, and model answers.</td>
		<td width="33%"><strong>Progress Insights</strong><br/>Session history, averages, and trend-ready reports.</td>
		<td width="33%"><strong>Premium Coaching</strong><br/>Stripe-backed upgrades with reliable access checks.</td>
	</tr>
	<tr>
		<td><strong>Daily Momentum</strong><br/>Reminders and follow-ups keep practice consistent.</td>
		<td><strong>Personalization</strong><br/>Profile-driven role, level, and stack settings.</td>
		<td><strong>Account and Data</strong><br/>Firebase auth and Firestore-backed storage.</td>
	</tr>
</table>

## Contribution guide

1. Fork the repository and create a feature branch.
2. Follow existing architecture patterns (feature-first, UI-only screens).
3. Add tests when practical and run `flutter test` before opening a PR.
4. Open a pull request with a clear description and screenshots if UI changes.

## License

See the LICENSE file for details.

## Contributors

| Contributor | GitHub |
| --- | --- |
| <img src="https://avatars.githubusercontent.com/AbdelrahmanSaid00?s=64" width="56" height="56" alt="AbdelrahmanSaid00" /><br/>AbdelrahmanSaid00 | https://github.com/AbdelrahmanSaid00 |
| <img src="https://avatars.githubusercontent.com/MaroWael?s=64" width="56" height="56" alt="MaroWael" /><br/>MaroWael | https://github.com/MaroWael |
| <img src="https://avatars.githubusercontent.com/IslamAli-0?s=64" width="56" height="56" alt="IslamAli-0" /><br/>IslamAli-0 | https://github.com/IslamAli-0 |
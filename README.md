# DevCircle Auth - Track 2: Firebase with Flutter

**DevCircle** is a mini Discord for software engineering students. This repository is my **Track 2** submission and the **live, working app**:
people create accounts, log in, reset forgotten passwords, and chat in topics. **Everything is stored online, so a new user sees the full chat history.**

- **Courses used:** [Firebase FCM Flutter codelab](https://firebase.google.com/codelabs/firebase-fcm-flutter) (Track 2), [Flutter first codelab](https://codelabs.developers.google.com/codelabs/flutter-codelab-first) (Track 1, in `devcircle-ui`)
- **Student:** Palesa · **Reference code:** WTC-7WFDKS75

## What the app does
| Feature | Details |
|---|---|
| **Sign up** | Username, email, password; choose *Student* or *Personal* email (Firebase Authentication). |
| **Log in / log out** | Friendly errors: wrong password, no internet, too many attempts. |
| **Forgot password** | "Forgot password?" emails a reset link; the user opens it and creates a new password. Logged-in users can use the settings icon, then *Change password*. |
| **Shared chat** | Circles, topics, messages, resources and meetings are stored in **Cloud Firestore**. Everyone sees the same data and new messages appear instantly. |
| **Chat history** | A new user sees every earlier message. The newest 100 load first; "Load older messages" loads more. |
| **Unread badges** | Pink badge shows how many messages you haven't opened yet. |
| **Push notifications (FCM)** | Asks permission, saves the device token, shows a banner for messages that arrive while the app is open, and has a background handler. |
| **Security rules** | Profiles are private and only signed-in users can read chat data. |
| **Starts empty** | No sample data and no pre-made accounts. The first users create everything. |

## Project files
| File | Purpose |
|---|---|
| `lib/main.dart` | Starts Firebase, FCM background handler, `AuthGate` (shows login or app) |
| `lib/signup_page.dart`, `login_page.dart`, `forgot_password_page.dart`, `password_field.dart` | Account screens |
| `lib/home_page.dart` | Main screen: circles, user card, settings menu |
| `lib/sidebar.dart` | Live topics / resources / meetings with unread badges |
| `lib/chat_view.dart` | Live chat for one topic |
| `lib/helpers.dart`, `theme.dart`, `shell_widgets.dart` | Dialogs, dark theme, reusable widgets |
| `lib/notification_service.dart` | Push notification setup |
| `lib/firebase_options.dart` | Firebase connection settings (generated) |
| `firestore.rules` | Database security rules |

## Run the checks
This app needs a private Firebase project to connect to, so only the checks are listed here.


```bash
flutter pub get          # download packages (first time only)
flutter analyze          # checks the code for mistakes. Expected: "No issues found!"
flutter test             # runs everything in the test/ folder. Expected: "All tests passed!"
```

| Command | What it does |
|---|---|
| `flutter test` | Runs all tests in `test/` |
| `flutter test test/widget_test.dart` | Runs just one test file |
| `flutter test --reporter expanded` | Shows the name of every test as it runs |
| `flutter test --coverage` | Also writes a coverage report to `coverage/lcov.info` |

**What is tested:** `test/widget_test.dart` is a small starter test. This app talks to Firebase (a live online service), so the real checks are done by hand with the live demo (sign up, chat between two users, history, password reset). The Firebase security rules can also be tried in the Firebase console, under Firestore -> Rules -> **Rules Playground**.

**If a test fails:** read the first red error line, run `flutter pub get` and try again. `flutter analyze` must also be clean before you submit.

## Limits (honest notes)
- Push notifications are sent from the Firebase console. Sending one automatically for every new message needs Cloud Functions (not included).
- No moderation yet (no edit or delete), and the student-email choice is not verified.
- Windows and Linux desktop are not supported by this Firebase setup. Use the web version there.
- Firebase's free plan has daily read/write limits.

## Screenshots
All screenshots were taken from the running app (Flutter web) connected to my Firebase project.

### 1. Creating an account
| Sign up screen | Duplicate email is rejected |
|---|---|
| ![Sign up](screenshots/signup.jpg) | ![Email already used](screenshots/duplicate-email.jpg) |
| Choose **Personal** or **Student** email, then enter username, email and password. | Signing up with an email that already exists shows a friendly message: *"That email already has an account. Try logging in."* |

### 2. Forgot password
| Reset email from Firebase | Create a new password |
|---|---|
| ![Reset email](screenshots/reset-email.jpg) | ![Reset page](screenshots/reset-password.jpg) |
| After tapping **Forgot password?**, Firebase emails a reset link (the link is blurred here). | The link opens Firebase's page where the user types a **new password** and presses **Save**. |

### 3. Using the app
| Empty home (first user) | Shared chat with two users and a resource |
|---|---|
| ![Empty home](screenshots/empty-home.jpg) | ![Chat](screenshots/shared-chat.jpg) |
| A brand-new app is **empty**: *No topics yet*, *No resources yet*, *No meetings scheduled*. | Two different users (`Lesa` and `Lee_codes`) chat in the topic **Functions (python)**. A shared resource opens in a dialog with a **Copy link** button. |

### 4. Scheduling a meeting
| Pick a date | Pick a time | Meeting details |
|---|---|---|
| ![Date](screenshots/meeting-date.jpg) | ![Time](screenshots/meeting-time.jpg) | ![Meeting](screenshots/meeting-details.jpg) |
| Step 1: choose the day. | Step 2: choose the time. | The meeting appears under **MEETINGS** for everyone, with its link and who set it up. |

## What I learned
- Firebase Authentication: sign up, log in, password reset, and `authStateChanges()` to switch screens automatically.
- Cloud Firestore: saving data, live `snapshots()` streams, and why security rules matter.
- Push notifications: permission, device token, foreground and background messages.
- How a database design (circles, topics, messages) lets every user share the same history.
-----------------------------------------------------------------------------------------------------------------
WTC-7WFDKS75

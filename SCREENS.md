# ClashChat — Screen Design Descriptions

This document describes all active user screens in the ClashChat Flutter application, detailing their layout, file locations, routing behavior, and features.

---

## 1. Splash Screen
**File:** `lib/screens/splash_screen.dart`

The entry point of the application. A quiet wordmark reveal: "Clash" in ink, "Chat" in brass, a short brass rule and the tagline "Argue better." Once the reveal completes:
- It checks `AuthService.isLoggedIn` and validates the user session via `SessionService.isSessionValid()`.
- If logged in and valid, routes to the **Home Screen**.
- Otherwise, routes to the **Login Screen**.

---

## 2. Login Screen
**File:** `lib/screens/login_screen.dart`

The authentication screen. Follows the app theme (light or dark). A left-aligned heading, a Login / Sign up segmented control, labelled fields and a single primary button; on desktop a brand panel sits beside the form. Tabs:
- **Login**: Email and password fields with a submission button.
- **Sign Up**: Email, password, and display name fields.
- **Social Sign-In**: a secondary "Continue with Google" button.
- **Forgot password**: sends a Firebase reset email to the address in the email field.
Upon successful auth, routes to the **Home Screen**.

---

## 3. Home Screen (Shell & Dashboard)
**File:** `lib/screens/home_screen.dart`

The primary navigation shell of the application. It contains a bottom navigation bar managing four screens:
- **Home (Dashboard)** (`_HomeBody`): Displays the main game portal.
- **History**: Pushes the list of past debates.
- **Profile**: Displays user rank, stats, and settings.
- **Settings**: App preferences and appearance.

The core **Home Dashboard** contains:
- **Header**: time-of-day greeting, display name and the Dicebear avatar ringed in the rank color.
- **Rank card**: rank icon, title, points (monospace) and progress to the next rank.
- **Usage card**: debates used today out of the daily quota of 40, with a progress bar and a lock state.
- **Game Modes**: one grouped list with three rows routing to the start of a debate:
  1. **Casual Mode**: Free practice with custom difficulty and timer constraints.
  2. **Ranked Mode**: Competitive match with points on the line, difficulty matched to user rank, and fixed 10-minute timers.
  3. **Learning Mode**: Coached mode providing constructive real-time debate analysis.

---

## 4. Topic Screen
**File:** `lib/screens/topic_screen.dart`

First step in setting up a debate. Users choose a category or input a custom topic:
- Displays 8 preset categories (Technology, Education, Society, Health, Politics, Environment, Economy, Culture) as a grid of selectable icon cards.
- Provides a custom text input field.
- Navigates to the **Stance Screen** on confirmation.

---

## 5. Stance Screen
**File:** `lib/screens/stance_screen.dart`

Second step in setup. Users select their argument stance:
- Two large selectable cards, **For** (sage) and **Against** (terracotta).
- **Routing Logic**:
  - **Learning Mode**: Navigates directly to the **Chat Screen** (with "Adaptable" difficulty).
  - **Casual Mode**: Pushes to the **Debate Setup Screen**.
  - **Ranked Mode**: Pushes to the **Ranked Setup Screen**.

---

## 6. Debate Setup Screen
**File:** `lib/screens/debate_setup_screen.dart`

Casual Mode setup. Allows players to configure details of their practice session:
- **Difficulty Selection**: a grouped list of Easy, Medium and Hard rows with radio-style selection.
- **Timer Switch**: Toggle to enable a custom debate timer with a minutes slider.
Tapping the action button launches the **Chat Screen**.

---

## 7. Ranked Setup Screen
**File:** `lib/screens/ranked_setup_screen.dart`

Ranked Mode preview. Displays competitive matchmaking parameters:
- States plainly that the opponent is calibrated to the player's current rank (no fake matchmaking), lists the fixed rules (10-minute timer, difficulty, topic, stance)
- Previews competitive points on the line.
Tapping start launches the **Chat Screen**.

---

## 8. Chat Screen
**File:** `lib/screens/chat_screen.dart`

The interactive debate interface:
- **App Bar**: Displays topic, current stance badge, and remaining timer.
- **Message List**: user messages are right-aligned brass bubbles; AI replies are left-aligned raised-surface bubbles. Timestamps appear once per run of messages.
- **Typing Indicator**: Shows bouncing dots while the AI endpoint processes.
- **Learning Mode**: Underneath the AI counter-argument, a separate card highlights the AI debate coach's tips and feedback on the user's last message.
Tapping **"End"** in the app bar triggers the final scoring and routes to the **Results Screen**.

---

## 9. Results Screen
**File:** `lib/screens/results_screen.dart`

The review page displayed after scoring completes:
- **Score Ring**: a brass ring with the score in monospace, animated from zero.
- **Stat Cards**: messages exchanged, duration and difficulty.
- **Feedback Lists**: "What worked" and "What to sharpen" as hairline-divided rows, plus a collapsible transcript.
- **Actions**: a primary "Debate again" and a secondary "Back to home" button.

---

## 10. History Screen
**File:** `lib/screens/history_screen.dart`

Accessed from navigation. Displays past debate history:
- **Summary Metrics**: Top strip listing total debates, average score, and wins (score ≥ 70).
- **History Cards**: Interactive cards displaying topic, stance, score, and date. Tapping a card opens its details in the **Results Screen** in read-only history mode.
- **Filter Sheet**: Bottom sheet modal to filter debates by stance and minimum score.

---

## 11. Profile Screen
**File:** `lib/screens/profile_screen.dart`

Accessed from navigation. Displays user account info and credentials setup:
- Displays circular Dicebear avatar, display name, email, and bio.
- **Stats Chips**: Displays profile statistics matching History (total debates, average score, wins).
- **Edit Mode**: Allows updating display name and bio directly in Firestore.
- **Password Check**: Clicking "Change Password" checks if `isGoogleSignIn` is true. If true, routes to **Create Password Screen**; if false, routes to **Change Password Screen**.

---

## 12. Avatar Picker Screen
**File:** `lib/screens/avatar_picker_screen.dart`

Accessed by tapping the avatar in edit mode:
- Allows selecting or randomizing custom Dicebear seed words.
- Displays responsive preview cards of the generated SVG avatars.
- Updates the seed back in the profile document upon selection.

---

## 13. Create Password Screen
**File:** `lib/screens/create_password_screen.dart`

Allows Google Sign-In users who have not yet configured a password to add credentials for email logins:
- Validates password guidelines (minimum 8 characters, 1 uppercase letter, 1 number).
- Updates password in Firebase Auth and flips the `isGoogleSignIn` Firestore flag to false.

---

## 14. Change Password Screen
**File:** `lib/screens/change_password_screen.dart`

Allows standard email/password users to change passwords:
- Validates current password via Firebase reauthentication.
- Validates and updates the new password.

---

## 15. Settings Screen
**File:** `lib/screens/settings_screen.dart`

Accessed from navigation. Features options for:
- **Appearance**: Dark Mode toggle changing themes dynamically via `ThemeProvider`.
- **Preferences**: Switches for notifications, sound, and timers (currently stubs).
- **About**: Displays version metrics and links to terms/privacy policies.

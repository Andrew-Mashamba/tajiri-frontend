# Firebase Live Update — Troubleshooting

## 1. Firestore: `PERMISSION_DENIED` / "Missing or insufficient permissions"

**Symptom:**  
`[LiveUpdate] Listen error: [cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.`

**Cause:**  
Firestore rules expect **Firebase Auth** (`request.auth.uid == userId`). The TAJIRI app uses **your own auth** (user_profiles.id) and does **not** sign in to Firebase. So there is no `request.auth`, and the rule denies read.

**Solutions (pick one):**

### A. Firebase Custom Token (recommended for production)

1. **Backend:** When a user logs in, use the Firebase Admin SDK to create a **custom token** with `uid` = that user’s `user_profiles.id` (as string, e.g. `"4"`).
2. **Flutter:** After your app has the token from your API, sign in to Firebase:
   ```dart
   import 'package:firebase_auth/firebase_auth.dart';
   await FirebaseAuth.instance.signInWithCustomToken(tokenFromYourApi);
   ```
3. **Firestore rules** (unchanged):  
   `allow read: if request.auth != null && request.auth.uid == userId;`  
   Document ID is `userId` (e.g. `"4"`), and custom token `uid` is `"4"`, so the rule passes.

### B. Temporary rule for development (no Firebase Auth)

Only for **development/testing**. In Firestore Console → Rules, use the same structure as in the repo’s **`firestore.rules`**, but for `match /updates/{userId}` set:

```
allow read: if true;
allow write: if false;
```

(So you keep your default-deny `match /{document=**}` block and only relax read for `updates/{userId}`.) This allows any client to read any `updates/{userId}` document. Your backend still writes with the service account. **Revert to A (custom token) for production** and use the production rule in `firestore.rules` so users can only read their own document.

---

## 2. Android: `DEVELOPER_ERROR` / "Unknown calling package name 'com.google.android.gms'"

**Symptom:**  
`GoogleApiManager: Failed to get service from broker` and `SecurityException: Unknown calling package name 'com.google.android.gms'` or `ConnectionResult{statusCode=DEVELOPER_ERROR}`.

**Cause:**  
The Android app’s **package name** or **SHA-1** fingerprint is not correctly registered in the Firebase project for the Android app.

**Fix:**

1. **Package name**  
   Must match exactly: `tz.co.zima.tajiri` (from `android/app/build.gradle.kts`).

2. **Add SHA-1 (and SHA-256) for the keystore you use to run the app:**
   - **Debug:**  
     ```bash
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
     ```
   - Copy the **SHA-1** (and optionally SHA-256) line.
   - **Firebase Console** → Project **tajiri-6d6ae** → ⚙️ **Project settings** → **Your apps** → select the **Android** app (`tz.co.zima.tajiri`).
   - Click **Add fingerprint**, paste SHA-1, save. Add SHA-256 if you use it elsewhere.

3. **Download the updated `google-services.json`** and replace `android/app/google-services.json`, then rebuild.

4. For **release** builds, add the SHA-1 of your **release** keystore the same way.

---

## 3. Backend 500 / "Profile not found" / "Server Error"

These come from your **Laravel API** (e.g. `ProfileService`, `PostService`), not from Firebase. Fix the API (route, auth, or handler) so it returns 200 with the expected JSON. Firebase live-update only triggers refetch; it does not change how the API responds.

---

## Summary

| Issue | Fix |
|-------|-----|
| Firestore **permission-denied** | Use Firebase Custom Token (uid = user_profiles.id) and keep strict rules, **or** temporary `allow read: if true` for `updates/{userId}` in development only. |
| Android **DEVELOPER_ERROR** | Add correct package name and SHA-1 (and SHA-256) in Firebase Console for the Android app, update `google-services.json`, rebuild. |
| API 500 / profile not found | Fix backend; unrelated to Firebase. |

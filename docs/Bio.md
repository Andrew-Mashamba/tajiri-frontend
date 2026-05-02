1. Rename the toggle honestly (do today, 5 min)

Current: "Biometric login" — implies it skips phone+PIN. False.                                                                                                                                                                        
Better: "Biometric unlock" — only unlocks the local app between sessions. Pair with a clear subtitle: "Use fingerprint or face to skip PIN entry when reopening the app."

2. Add a real biometric-login flow (proper architecture)

┌─────────────────────────────────────────────────────────┐                                                                                                                                                                            
│ At enrollment (after first successful PIN login):       │                                                                                                                                                                            
│  1. Generate a Keystore/Keychain key bound to biometric │                                                                                                                                                                            
│  2. Encrypt the refresh_token with that key             │                                                                                                                                                                            
│  3. Store ciphertext locally; key never leaves enclave  │     
└─────────────────────────────────────────────────────────┘                                                                                                                                                                            
↓                                                                                                                                                                                                            
┌─────────────────────────────────────────────────────────┐                                                                                                                                                                            
│ At next sign-in (session expired or user signed out):   │                                                                                                                                                                            
│  1. Show biometric prompt with CryptoObject(cipher)     │                                                                                                                                                                            
│  2. On success: cipher decrypts refresh_token           │                                                                                                                                                                            
│  3. POST /api/auth/refresh with that token              │                                                                                                                                                                            
│  4. Receive fresh access+refresh, re-encrypt new        │
│     refresh, replace stored ciphertext                  │                                                                                                                                                                            
└─────────────────────────────────────────────────────────┘                                                                                                                                                                            
↓                                                                                                                                                                                                            
┌─────────────────────────────────────────────────────────┐                                                                                                                                                                            
│ Always available as fallback: phone + 4-digit PIN       │     
└─────────────────────────────────────────────────────────┘

The flutter_secure_storage package TAJIRI already uses supports this on iOS (Keychain access control), and the local_auth + cryptography combination on Android. No new dependency required.

3. Required guardrails (non-negotiable)

┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┬─────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                          Rule                                                          │                                                   Why                                                   │   
├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ PIN always works, even if biometric is enabled                                                                         │ Signal-style lockout when sensor fails. Tanzania users on cheap Androids have unreliable fingerprint    │   
│                                                                                                                        │ sensors                                                                                                 │
├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────┤   
│ Class 3 / BIOMETRIC_STRONG only for the crypto-bound flow                                                              │ Class 2 (face-only on weak hardware) has high false-accept rate; banks reject it                        │
├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Invalidate on enrollment change                                                                                        │ If user adds a new fingerprint, old encrypted token must die — otherwise a new enrollment can read your │   
│                                                                                                                        │  stored refresh token                                                                                   │   
├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────┤   
│ Never call biometric on splash screen                                                                                  │ Friction → conversion drop                                                                              │   
├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Show biometric type in copy: "Fingerprint" vs "Face ID" vs generic "Biometric" depending on what the device has        │ UX clarity — local_auth exposes getAvailableBiometrics()                                                │   
├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Re-prompt biometric for sensitive actions (PIN change, wallet PIN change, large transfers in Tajiri Pay) — don't trust │ Banking-grade pattern                                                                                   │   
│  an active session for these                                                                                           │                                                                                                         │
└────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┴─────────────────────────────────────────────────────────────────────────────────────────────────────────┘

4. What to remove from the current screen

- The auto-lock timeout chips I built (Immediate/1/5/15 min) belong here, but they're toggled in seconds in the backend (app_lock_timeout_seconds). Today the backend default is 0 (immediate). That's broken UX — confirm the chip    
  selection actually persists. Worth a smoke test.
- The biometric switch should be disabled with explainer when:
    - No PIN set (already done)
    - No biometric enrolled on device (need to add — local_auth.canCheckBiometrics returns false)
    - Device only supports Class 2 (need to add — for the future crypto-bound flow)

5. Backend changes worth queuing

┌────────────────────────────────────────────────────────────────────────────────────────────────────────┬─────────────────────────────────────────────────────────────────────┐                                                       
│                                                 Change                                                 │                                 Why                                 │                                                       
├────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────┤                                                       
│ New endpoint: POST /api/auth/biometric-enroll — accepts a device-generated public key                  │ Required for the crypto-signature pattern (Telegram-style passkeys) │                                                       
├────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────┤
│ New endpoint: POST /api/auth/biometric-login — accepts a signed challenge                              │ The actual server-verified biometric login                          │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────┤
│ personal_access_tokens.is_biometric boolean                                                            │ Audit trail: which sessions came from biometric vs PIN              │
├────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────┤                                                       
│ security_activity_log event types: biometric_enrolled, biometric_login_success, biometric_login_failed │ Already have the table — just add the producers                     │                                                       
└────────────────────────────────────────────────────────────────────────────────────────────────────────┴─────────────────────────────────────────────────────────────────────┘                                                       
                          
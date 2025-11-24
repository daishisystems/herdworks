# Authentication Error Messages Reference

This document lists all user-facing error messages for authentication flows.

## Sign In Errors

| Error Code | User Message | When It Happens |
|------------|--------------|-----------------|
| `invalidEmail` | "The email address is invalid. Please check and try again." | Email format is wrong |
| `invalidCredential` | "Incorrect email or password. Double-check your password or use 'Forgot Password' to reset it." | **Wrong password or email doesn't exist** |
| `wrongPassword` | "Incorrect email or password. Double-check your password or use 'Forgot Password' to reset it." | Legacy wrong password (Firebase deprecated) |
| `userNotFound` | "No account found with this email. Please check your email address or sign up for a new account." | Email not registered |
| `userDisabled` | "This account has been disabled. Please contact support." | Account banned/disabled |
| `tooManyRequests` | "Too many failed attempts. Please wait 10-15 minutes and try again." | Rate limited by Firebase |
| `networkError` | "Network error. Please check your internet connection and try again." | No internet |
| `userTokenExpired` | "Your session has expired. Please sign in again." | Session expired |
| `requiresRecentLogin` | "This action requires a recent login. Please sign in again." | Sensitive operation needs re-auth |

## Sign Up Errors

| Error Code | User Message | When It Happens |
|------------|--------------|-----------------|
| `emailAlreadyInUse` | "This email is already in use. Please sign in instead." | Email already registered |
| `weakPassword` | "Password is too weak. Use at least 6 characters." | Password < 6 characters |
| `invalidEmail` | "The email address is invalid. Please check and try again." | Invalid email format |
| `operationNotAllowed` | "Email/password sign-in is not enabled. Please contact support." | Auth method disabled in Firebase |

## Password Reset Errors

| Error Code | User Message | When It Happens |
|------------|--------------|-----------------|
| `invalidEmail` | "The email address is invalid. Please check and try again." | Invalid email format |
| `userNotFound` | "No account found with this email. Please check the email address or sign up." | Email not registered |
| `tooManyRequests` | "Too many attempts. Please wait 10-15 minutes and try again." | Rate limited |

## Default/Unknown Errors

For any unhandled error codes:
**"Unable to sign in. Please check your email and password and try again."**

## Notes

- **Security**: Firebase intentionally uses `invalidCredential` for both wrong password AND non-existent email to prevent email enumeration attacks
- **Password Reset Guidance**: Error messages now explicitly suggest using "Forgot Password" to help users recover their accounts
- **Spam Folder Warning**: Password reset alert now includes a reminder to check spam folders
- **Rate Limiting**: After 5-10 failed attempts, Firebase blocks the IP for 10-15 minutes
- **Email Trimming**: All emails are automatically trimmed of whitespace
- **Case Sensitivity**: Firebase emails are case-insensitive
- **Password Requirements**: Minimum 6 characters (Firebase default)

## Testing

To test error messages:
1. **Wrong password**: Use valid email with incorrect password → Shows "Incorrect email or password"
2. **Non-existent email**: Use fake email → Shows "Incorrect email or password" (same as #1 for security)
3. **Invalid format**: Use "notanemail" → Shows "The email address is invalid"
4. **Weak password**: Sign up with "12345" → Shows "Password is too weak"
5. **Rate limiting**: Try wrong password 10 times → Shows "Too many failed attempts"
6. **Network**: Turn on Airplane mode → Shows "Network error"

## Debug Logging

In debug builds, the console will show:
- Exact Firebase error codes
- Raw error messages
- Which authentication operation failed
- User email (for debugging)

Production builds only show user-friendly messages.

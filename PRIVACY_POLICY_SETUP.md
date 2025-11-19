# Privacy Policy Setup Guide

This guide explains how to host and configure the HerdWorks Privacy Policy for App Store submission.

## Files Created

1. **PRIVACY_POLICY.md** - Markdown version for documentation
2. **privacy-policy.html** - HTML version for web hosting
3. **PRIVACY_POLICY_SETUP.md** - This file (setup instructions)

## Required Actions Before App Store Submission

### 1. Update Contact Information

**CRITICAL:** Replace placeholder information in both privacy policy files:

#### Email Address
- **Current:** `support@herdworks.app`
- **Action:** Replace with your actual support email
- **Files to update:**
  - `PRIVACY_POLICY.md` (multiple occurrences)
  - `privacy-policy.html` (multiple occurrences)

#### Business Address
- **Current:** `[Your Business Address]`
- **Action:** Add your actual business or personal address
- **Files to update:**
  - `PRIVACY_POLICY.md` (Contact Us section)
  - `privacy-policy.html` (Contact Us section)

#### Data Protection Officer (Optional)
- **Current:** `[If applicable]`
- **Action:** If you have a DPO, add their contact info; otherwise, remove this line
- **Files to update:**
  - `PRIVACY_POLICY.md` (Contact Us section)
  - `privacy-policy.html` (Contact Us section)

### 2. Host the Privacy Policy Online

**REQUIRED:** The privacy policy must be accessible via a public URL for App Store submission.

#### Option A: GitHub Pages (Free, Recommended for MVP)

1. **Create a GitHub Pages repository:**
   ```bash
   # Option 1: Use existing repository
   # Copy privacy-policy.html to a 'docs' folder
   mkdir -p docs
   cp privacy-policy.html docs/index.html

   # Commit and push
   git add docs/index.html
   git commit -m "docs: Add privacy policy for App Store"
   git push origin main
   ```

2. **Enable GitHub Pages:**
   - Go to repository Settings → Pages
   - Source: Deploy from branch
   - Branch: `main`, Folder: `/docs`
   - Save

3. **Your URL will be:**
   ```
   https://[your-username].github.io/[repository-name]/
   ```

4. **Verify access:**
   - Open the URL in a browser
   - Ensure the privacy policy loads correctly

#### Option B: Custom Website (Recommended for Production)

If you have a HerdWorks website (e.g., `www.herdworks.app`):

1. Upload `privacy-policy.html` to your web server
2. Place it at: `https://www.herdworks.app/privacy-policy.html`
3. Ensure it's accessible via HTTPS (required by Apple)

#### Option C: Simple Static Hosting

Alternative free hosting options:
- **Netlify:** Drag-and-drop `privacy-policy.html` → Get instant URL
- **Vercel:** Similar to Netlify, free tier available
- **Firebase Hosting:** Since you're already using Firebase

### 3. Configure App Store Connect

Once the privacy policy is hosted:

1. **Copy the Privacy Policy URL:**
   - Example: `https://herdworks.app/privacy-policy.html`

2. **Add to App Store Connect:**
   - Log in to App Store Connect
   - Navigate to your app → App Information
   - Find "Privacy Policy URL" field
   - Paste your privacy policy URL
   - Save

3. **Test the URL:**
   - Click the link in App Store Connect to verify it works
   - The URL must be publicly accessible (no login required)
   - Must use HTTPS (not HTTP)

### 4. Complete App Privacy Questionnaire

In App Store Connect, you'll need to answer Apple's privacy questions:

#### Data Collection - Based on HerdWorks Privacy Policy

**Contact Info:**
- ✅ **Email Address** - Used for authentication and communication
- ✅ **Name** - First and last name for personalization
- ✅ **Phone Number** - For account verification
- ✅ **Physical Address** - User's personal address

**User Content:**
- ✅ **Other User Content** - Farm data, breeding records, scanning events, lambing records

**Identifiers:**
- ✅ **User ID** - Firebase UID for account management

**NOT Collected:**
- ❌ Precise Location
- ❌ Coarse Location
- ❌ Photos or Videos
- ❌ Payment Info
- ❌ Browsing History
- ❌ Search History
- ❌ Contacts
- ❌ Device ID (for advertising)

#### Data Usage - For Each Data Type

For **each** data type you selected, specify usage:

**Email Address, Name, Phone Number, Physical Address:**
- [ ] App Functionality (Primary reason)
- [ ] Product Personalization
- [ ] Developer Communications

**Farm Data (User Content):**
- [ ] App Functionality (Primary reason)
- [ ] Analytics (Anonymized benchmarking)
- [ ] Product Personalization

**User ID:**
- [ ] App Functionality (Primary reason)
- [ ] Developer Communications

#### Data Linked to User

All collected data in HerdWorks is **linked to the user's identity** (tied to their account).

**Answer YES to "Is this data linked to the user?"** for all data types.

#### Data Used to Track User

HerdWorks does **NOT** use data for tracking across apps/websites for advertising.

**Answer NO to "Is this data used to track the user?"** for all data types.

### 5. Add Privacy Policy Link to App (Optional but Recommended)

While not required by Apple, it's good practice to link to the privacy policy from within the app:

#### Suggested Location: Settings View

Add a button in `SettingsView.swift`:

```swift
Section {
    Button(action: {
        if let url = URL(string: "https://herdworks.app/privacy-policy.html") {
            UIApplication.shared.open(url)
        }
    }) {
        HStack {
            Image(systemName: "hand.raised.fill")
                .foregroundStyle(.secondary)
            Text("Privacy Policy")
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "arrow.up.right.square")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
    .buttonStyle(.plain)
}
```

### 6. Account Deletion Feature (App Store Requirement)

**CRITICAL:** If your app allows account creation, you **must** provide a way to delete accounts.

#### Current Status
Check if HerdWorks has account deletion functionality:
- [ ] In-app account deletion button (Settings → Delete Account)
- [ ] Alternative method documented (email support to request deletion)

#### Implementation (If Missing)

Add to `ProfileTab` or `SettingsView`:

```swift
Section {
    Button(role: .destructive, action: {
        showingDeleteAccountAlert = true
    }) {
        HStack {
            Image(systemName: "trash")
            Text("Delete Account")
        }
    }
}
.alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
    Button("Cancel", role: .cancel) { }
    Button("Delete", role: .destructive) {
        Task {
            await deleteAccount()
        }
    }
} message: {
    Text("This will permanently delete your account and all farm data. This action cannot be undone.")
}
```

**Backend Implementation:**
- Delete user data from Firestore (farms, breeding events, scanning events, lambing records)
- Delete user profile from Firestore
- Delete Firebase Auth account
- Log user out

## Verification Checklist

Before submitting to App Store, verify:

- [ ] Privacy policy hosted at a public HTTPS URL
- [ ] URL is accessible without authentication
- [ ] Contact information (email, address) is updated
- [ ] Privacy Policy URL added to App Store Connect
- [ ] App Privacy questionnaire completed in App Store Connect
- [ ] All data types disclosed accurately
- [ ] Data usage purposes specified correctly
- [ ] Account deletion functionality available (in-app or via support)
- [ ] (Optional) Privacy policy link added to app settings
- [ ] (Optional) Terms of Service created (not required, but recommended)

## Common App Store Rejection Reasons Related to Privacy

Avoid these issues:

1. **Privacy Policy URL is dead/inaccessible**
   - Test your URL before submission
   - Use a reliable hosting service

2. **Privacy Policy doesn't match actual data collection**
   - Ensure your privacy policy accurately reflects what your app collects
   - Update the policy if you add new features that collect data

3. **Missing account deletion**
   - If you collect account information, you MUST provide account deletion
   - Either in-app or via documented support contact

4. **Incorrect privacy questionnaire answers**
   - Be honest about data collection
   - Apple tests apps and will reject if answers don't match actual behavior

5. **Privacy policy is generic/template**
   - Customize the privacy policy to your actual app
   - Remove placeholder text like `[Your Business Address]`

## Future Updates

If you add new features that collect additional data:

1. **Update the privacy policy** with new data types
2. **Update "Last Updated" date** at the top
3. **Notify users** via in-app alert or email (for significant changes)
4. **Update App Store Connect** privacy questionnaire if needed
5. **Submit updated privacy answers** with your next app version

## Support Resources

- **Apple Privacy Guidelines:** https://developer.apple.com/app-store/app-privacy-details/
- **Firebase Privacy:** https://firebase.google.com/support/privacy
- **POPIA (South Africa):** https://inforegulator.org.za/
- **GDPR (Europe):** https://gdpr.eu/

## Questions?

If you need help with privacy policy setup:
1. Review Apple's App Privacy Details documentation
2. Consult with a legal professional for specific advice
3. Reach out to Firebase support for data handling questions

---

**Next Steps:**

1. ✅ Privacy policy drafted
2. ⏳ Update contact information (email, address)
3. ⏳ Host privacy policy online (GitHub Pages or custom domain)
4. ⏳ Add privacy policy URL to App Store Connect
5. ⏳ Complete App Privacy questionnaire
6. ⏳ Verify account deletion functionality exists

Once these steps are complete, the privacy policy requirement for App Store submission will be satisfied.

# App Store Readiness - Action Items

**Last Updated:** January 19, 2025
**Project:** HerdWorks iOS App
**Goal:** Prepare for App Store submission

---

## Progress Overview

### ✅ Completed (2/7 Major Tasks)

1. **✅ Task 1.1: Store Memory Leak Fix**
   - Status: Merged to main via PR #2
   - Impact: Eliminated critical memory leak from duplicate store instances
   - Files: 8 files changed, store lifecycle properly managed

2. **✅ Task 1.2: Accessibility Support**
   - Status: On branch `claude/task-1.2-accessibility-support-01BnbW7cUodc1EirbFiA4yxr`
   - Impact: 35% accessibility coverage (77/222 elements)
   - Files: 180+ localized strings, 6 views updated
   - **Action Required:** Create PR and merge to main

3. **✅ Privacy Policy Draft**
   - Status: Completed - 3 files created
   - Files:
     - `PRIVACY_POLICY.md` (Markdown documentation)
     - `privacy-policy.html` (Web-ready HTML)
     - `PRIVACY_POLICY_SETUP.md` (Setup instructions)
   - **Action Required:** Update contact info and host online

---

## 🚨 Critical Blockers (MUST FIX)

These items will cause App Store rejection if not addressed:

### 1. Account Deletion Functionality (HIGH PRIORITY)

**Status:** ❌ NOT IMPLEMENTED
**Apple Requirement:** Apps that support account creation MUST provide account deletion

**What's Needed:**
- In-app "Delete Account" button (recommended location: Settings or Profile)
- Confirmation dialog with warning about data loss
- Backend implementation to delete:
  - All farm data (farms, breeding events, scanning, lambing records)
  - User profile from Firestore
  - Firebase Auth account
- User logout after deletion

**Estimated Time:** 4-6 hours
**Implementation Priority:** CRITICAL - Block all other work until this is done

**Suggested Implementation Location:**
- File: `LandingView.swift` → `ProfileTab` section
- OR: `SettingsView.swift` (if dedicated settings view exists)

**Code Example Provided in:** `PRIVACY_POLICY_SETUP.md` (Section 6)

---

### 2. Privacy Policy Hosting

**Status:** ✅ Drafted, ⏳ Needs Hosting
**Apple Requirement:** Publicly accessible HTTPS URL required

**What's Needed:**
1. Update contact information in both files:
   - Replace `support@herdworks.app` with real email
   - Replace `[Your Business Address]` with actual address
   - Remove or fill in `[If applicable]` placeholders

2. Host `privacy-policy.html` online:
   - **Option A:** GitHub Pages (free, quick)
   - **Option B:** Custom domain (e.g., `herdworks.app/privacy-policy.html`)
   - **Option C:** Firebase Hosting, Netlify, or Vercel

3. Add URL to App Store Connect

**Estimated Time:** 1-2 hours
**Implementation Priority:** CRITICAL

**Detailed Instructions:** See `PRIVACY_POLICY_SETUP.md`

---

### 3. App Store Connect Privacy Questionnaire

**Status:** ⏳ Not Started
**Apple Requirement:** Must accurately disclose all data collection

**What's Needed:**
1. Log in to App Store Connect
2. Navigate to your app → App Privacy
3. Answer questionnaire based on privacy policy

**Data Types to Disclose:**
- ✅ Contact Info (email, name, phone, address)
- ✅ User Content (farm data)
- ✅ Identifiers (user ID)
- ❌ Location (NOT collected)
- ❌ Photos/Videos (NOT collected)
- ❌ Payment Info (NOT collected)

**Estimated Time:** 30 minutes
**Implementation Priority:** CRITICAL

**Detailed Guide:** See `PRIVACY_POLICY_SETUP.md` (Section 4)

---

## 📝 High Priority Tasks

### 4. App Store Metadata

**Status:** ⏳ Not Started
**Required for:** App Store submission

**What's Needed:**

#### A. App Description (Max 4000 characters)
- **Hook:** Compelling opening sentence
- **Features:** List key functionality (breeding, scanning, lambing, benchmarks)
- **Benefits:** Why farmers should use HerdWorks
- **Target Audience:** South African sheep farmers
- **Languages:** English (Afrikaans optional)

**Estimated Time:** 2-3 hours

#### B. Keywords (Max 100 characters)
- Example: `sheep,farming,livestock,breeding,lambing,agriculture,farm management`
- Research App Store search terms
- Avoid trademarked terms

**Estimated Time:** 30 minutes

#### C. Promotional Text (Max 170 characters)
- Can be updated without app review
- Use for seasonal promotions or feature highlights

**Estimated Time:** 15 minutes

#### D. Screenshots (CRITICAL)

**Required Sizes:**
- iPhone 6.7" Display (1290 x 2796 pixels) - 3 to 10 screenshots
- iPhone 6.5" Display (1242 x 2688 pixels) - Optional but recommended

**Screenshot Content Suggestions:**
1. Landing page with quick actions
2. Breeding events list
3. Benchmark comparison (showcase feature)
4. Scanning event form
5. Lambing season overview

**Tools:**
- Xcode Simulator (⌘+S for screenshot)
- Screenshot framing tools (Previewed.app, Screenshot Creator)

**Estimated Time:** 4-6 hours (including device testing and framing)

---

### 5. App Icon Verification

**Status:** ⏳ Not Verified
**Required:** App Store icon (1024x1024, no transparency)

**What's Needed:**
1. Verify icon exists in `Assets.xcassets/AppIcon`
2. Check all required sizes:
   - App Store: 1024x1024
   - iPhone: 60x60@2x, 60x60@3x
   - iPad (if supported): 76x76@2x, 83.5x83.5@2x
3. Ensure no alpha channel/transparency
4. Follows Apple HIG guidelines

**Estimated Time:** 1-2 hours (if redesign needed)

---

### 6. Demo Account for App Review

**Status:** ⏳ Not Created
**Apple Requirement:** Required if app has login

**What's Needed:**
1. Create a Firebase Auth account with test data:
   - Email: `appreviewer@herdworks.app` (or similar)
   - Password: Strong, memorable password
2. Add sample data:
   - 1-2 farms
   - Multiple breeding events
   - Scanning results
   - Benchmark data
3. Document credentials in App Store Connect "App Review Information"
4. **IMPORTANT:** Never delete this account

**Estimated Time:** 30 minutes

---

## 🧪 Testing Requirements

### 7. VoiceOver Testing (Accessibility)

**Status:** ⏳ Not Started
**Required:** Verify accessibility implementation works

**What's Needed:**
1. Enable VoiceOver on physical iPhone
2. Test complete user flows:
   - Tab navigation
   - Create breeding event
   - View benchmark comparison
   - Form inputs (text fields, pickers, date pickers)
3. Verify all labels are clear and hints are helpful
4. Test in both English and Afrikaans

**Estimated Time:** 2-3 hours
**Priority:** High (accessibility is a key differentiator)

---

### 8. Device Testing

**Status:** ⏳ Not Started
**Required:** Ensure app works on various devices

**Devices to Test:**
- iPhone SE (3rd gen) - Smallest screen
- iPhone 15 Pro - Standard size
- iPhone 15 Pro Max - Largest screen (use for screenshots)
- iPad (if supported)

**Test Scenarios:**
- Clean install
- Sign up flow
- Create farm and events
- Offline mode (airplane mode)
- Network errors
- Empty states
- Maximum data (100+ events)

**Estimated Time:** 4-6 hours

---

### 9. Build and Archive

**Status:** ⏳ Not Started
**Required:** Upload to App Store Connect

**What's Needed:**
1. Verify version numbers:
   - Marketing Version: `1.0.0`
   - Build Number: `1`
2. Configure signing (certificates and provisioning profiles)
3. Set deployment target (recommend iOS 17.0+)
4. Create archive: Product → Archive
5. Validate archive
6. Upload to App Store Connect
7. Wait for processing (15-60 minutes)

**Estimated Time:** 2-3 hours (including setup)

---

## ⚠️ Medium Priority (Nice to Have)

### 10. TestFlight Beta Testing

**Status:** ⏳ Optional
**Benefit:** Catch bugs before public release

**What's Needed:**
1. Upload build to TestFlight
2. Add 5-10 external testers
3. Collect feedback (1-2 weeks)
4. Fix critical bugs
5. Submit final build

**Estimated Time:** 1-2 weeks (waiting time)

---

### 11. Support URL

**Status:** ⏳ Not Created
**Required:** App Store Connect asks for support URL

**Options:**
- GitHub Issues page (quick solution)
- Support email page on website
- Dedicated support portal

**Estimated Time:** 30 minutes

---

### 12. Marketing URL

**Status:** ⏳ Optional
**Purpose:** Link to marketing website

**Options:**
- Create simple landing page
- Use GitHub repository
- Skip for v1.0 (optional field)

**Estimated Time:** 2-4 hours (if creating landing page)

---

## 📅 Recommended Timeline

### Week 1: Critical Blockers
- **Day 1-2:** Implement account deletion functionality
- **Day 2:** Update privacy policy contact info and host online
- **Day 3:** Complete App Store Connect privacy questionnaire
- **Day 4:** Create demo account with sample data
- **Day 5:** Verify app icon and bundle settings

### Week 2: Metadata and Testing
- **Day 1-2:** Write app description, keywords, and prepare screenshots
- **Day 3:** VoiceOver testing on physical device
- **Day 4:** Device testing across iPhone models
- **Day 5:** Fix any bugs found during testing

### Week 3: Submission
- **Day 1:** Create and validate archive
- **Day 2:** Upload to App Store Connect
- **Day 3:** Complete all App Store Connect fields
- **Day 4:** Submit for review
- **Day 5:** Monitor review status

**Total Timeline:** 3 weeks (optimistic) to 4-5 weeks (realistic)

---

## Critical Path (Minimum for Submission)

If you need to submit ASAP, focus on these tasks ONLY:

1. ✅ Merge accessibility branch (ready now)
2. 🚨 **Implement account deletion** (BLOCKER - 4-6 hours)
3. 🚨 **Host privacy policy online** (BLOCKER - 1-2 hours)
4. 🚨 **Complete privacy questionnaire** (BLOCKER - 30 minutes)
5. 📝 Create demo account (1 hour)
6. 📝 App description and keywords (2-3 hours)
7. 📝 Screenshots (4-6 hours)
8. 🧪 Basic testing (4-6 hours)
9. 📦 Build and upload (2-3 hours)
10. 📤 Submit for review

**Minimum Timeline:** 5-7 days of focused work

---

## Next Immediate Actions

### Right Now (Today):
1. **Create Pull Request** for accessibility branch
   - Use `PR_ACCESSIBILITY.md` as description
   - Merge to main after review

2. **Implement Account Deletion** (CRITICAL BLOCKER)
   - Add delete button to ProfileTab or SettingsView
   - Implement backend deletion logic
   - Test thoroughly (this is non-reversible!)

3. **Update Privacy Policy Contact Info**
   - Replace `support@herdworks.app` with real email
   - Add business address
   - Commit changes

### Tomorrow:
4. **Host Privacy Policy Online**
   - Choose hosting method (GitHub Pages recommended for speed)
   - Verify URL is accessible
   - Add URL to App Store Connect

5. **Complete Privacy Questionnaire**
   - Use `PRIVACY_POLICY_SETUP.md` as guide
   - Answer honestly based on actual data collection

### This Week:
6. **Create App Store Metadata**
   - Write compelling description
   - Research and select keywords
   - Take screenshots on largest iPhone

7. **Create Demo Account**
   - Add realistic sample data
   - Document credentials securely

---

## Resources Created

All documentation is in the repository:

1. **PR_ACCESSIBILITY.md** - Pull request description for accessibility work
2. **PRIVACY_POLICY.md** - Privacy policy (Markdown)
3. **privacy-policy.html** - Privacy policy (HTML for web)
4. **PRIVACY_POLICY_SETUP.md** - Detailed setup instructions
5. **APP_STORE_READINESS.md** - This file (complete action plan)

---

## Questions or Blockers?

If you encounter issues:

1. **Account Deletion Implementation:** Review Firebase Auth docs for account deletion
2. **Privacy Policy Hosting:** GitHub Pages is fastest free option
3. **App Store Connect:** Apple's documentation is comprehensive
4. **Technical Issues:** Check Xcode console for error messages

---

## Status Summary

| Task | Status | Priority | Time Est. | Blocker? |
|------|--------|----------|-----------|----------|
| Memory leak fix | ✅ Done | - | - | - |
| Accessibility | ✅ Done (needs merge) | High | 1h | No |
| Privacy policy draft | ✅ Done | - | - | - |
| **Account deletion** | ❌ **NOT DONE** | **CRITICAL** | **4-6h** | **YES** |
| **Privacy policy hosting** | ⏳ **In Progress** | **CRITICAL** | **1-2h** | **YES** |
| **Privacy questionnaire** | ⏳ **Not Started** | **CRITICAL** | **30m** | **YES** |
| App description | ⏳ Not Started | High | 2-3h | No |
| Keywords | ⏳ Not Started | High | 30m | No |
| Screenshots | ⏳ Not Started | High | 4-6h | No |
| App icon | ⏳ Not Verified | High | 1-2h | No |
| Demo account | ⏳ Not Started | High | 30m | No |
| VoiceOver testing | ⏳ Not Started | Medium | 2-3h | No |
| Device testing | ⏳ Not Started | Medium | 4-6h | No |
| Build & upload | ⏳ Not Started | High | 2-3h | No |

---

**🚨 CRITICAL: The #1 priority right now is implementing account deletion functionality. Everything else can wait, but this is a hard requirement from Apple.**

Start with account deletion, then move to privacy policy hosting. Once those two blockers are resolved, you can proceed with metadata and submission.

# App Store Connect Setup Guide

**Task 1:** Add Privacy Policy URL to App Store Connect
**Task 2:** Complete Privacy Questionnaire
**Estimated Total Time:** ~35 minutes

---

## 🎯 Task 1: Add Privacy Policy URL (3 minutes)

### Step 1: Log in to App Store Connect

1. Go to: **https://appstoreconnect.apple.com/**
2. Sign in with your Apple Developer account
3. You'll see the main dashboard

### Step 2: Navigate to Your App

**If app already exists in App Store Connect:**
1. Click **"My Apps"** (top left)
2. Click on **HerdWorks** (or whatever you named it)

**If app doesn't exist yet:**
1. Click **"My Apps"**
2. Click the **"+"** button (top left)
3. Click **"New App"**
4. Fill in the form:
   - **Platforms:** iOS
   - **Name:** HerdWorks
   - **Primary Language:** English (U.S.)
   - **Bundle ID:** Select your bundle ID (should be `com.herdworks` or similar)
   - **SKU:** `herdworks-ios-2025` (unique identifier, any alphanumeric)
   - **User Access:** Full Access
5. Click **"Create"**

### Step 3: Go to App Information

1. In the left sidebar, click **"App Information"**
2. Scroll down to the **"General Information"** section

### Step 4: Add Privacy Policy URL

1. Find the field labeled **"Privacy Policy URL"**
2. Enter your GitHub Pages URL:
   ```
   https://daishisystems.github.io/herdworks/
   ```
3. Click **"Save"** (top right)

### Step 5: Verify It Works

1. After saving, click the privacy policy URL you just entered
2. It should open in a new tab and display your privacy policy
3. If it works → You're done with Task 1! ✅

**Common Issues:**
- **"URL is not valid"** → Make sure it starts with `https://` (not `http://`)
- **"URL is not accessible"** → Wait a few minutes, GitHub Pages might still be deploying
- **404 Error** → Check that GitHub Pages is enabled and pointing to `/docs` folder

---

## 🎯 Task 2: Complete Privacy Questionnaire (30 minutes)

This is the **App Privacy** section where you tell Apple what data your app collects.

### Step 1: Navigate to App Privacy

1. Still in App Store Connect, in the left sidebar
2. Click **"App Privacy"** (under "General")
3. You'll see: "Get Started" or "Edit" button
4. Click **"Get Started"** (or "Edit" if already started)

---

### Step 2: Data Collection Overview

**First Question:** "Do you or your third-party partners collect data from this app?"

**Answer:** ✅ **YES**

Why? HerdWorks collects:
- Email, name, phone number (user profile)
- Farm data (breeding, scanning, lambing records)
- Firebase collects some technical data

Click **"Next"**

---

### Step 3: Select Data Types Collected

You'll see categories. Select the following:

#### ✅ **Contact Info**
Click **"Contact Info"** → Select these:
- ✅ **Email Address**
- ✅ **Name** (first and last name)
- ✅ **Phone Number**
- ✅ **Physical Address** (user's personal address in profile)

Click **"Next"**

#### ✅ **User Content**
Click **"User Content"** → Select:
- ✅ **Other User Content** (farm data, breeding records, etc.)

Click **"Next"**

#### ✅ **Identifiers**
Click **"Identifiers"** → Select:
- ✅ **User ID** (Firebase UID)

Click **"Next"**

#### ❌ **DO NOT SELECT:**
- ❌ Precise Location
- ❌ Coarse Location
- ❌ Photos or Videos
- ❌ Payment Info
- ❌ Browsing History
- ❌ Search History
- ❌ Device ID (for advertising)
- ❌ Purchase History
- ❌ Health & Fitness
- ❌ Financial Info
- ❌ Contacts
- ❌ Audio Data
- ❌ Sensitive Info

---

### Step 4: Configure Each Data Type

For **each data type** you selected, you'll answer 3 questions:

---

#### **Email Address**

**Question 1:** "How is this data used?"
Select:
- ✅ **App Functionality** (to create and manage user accounts)
- ✅ **Developer Communications** (to contact users about account/support)

**Question 2:** "Is this data linked to the user's identity?"
- ✅ **YES** (email is tied to their account)

**Question 3:** "Do you or your third-party partners use this data for tracking?"
- ❌ **NO** (not used for advertising or tracking across apps)

Click **"Next"**

---

#### **Name** (First and Last)

**Question 1:** "How is this data used?"
- ✅ **App Functionality** (to personalize user experience)
- ✅ **Product Personalization** (to address user by name)

**Question 2:** "Is this data linked to the user's identity?"
- ✅ **YES** (name is part of user profile)

**Question 3:** "Do you or your third-party partners use this data for tracking?"
- ❌ **NO**

Click **"Next"**

---

#### **Phone Number**

**Question 1:** "How is this data used?"
- ✅ **App Functionality** (for user profile)
- ✅ **Developer Communications** (optional contact method)

**Question 2:** "Is this data linked to the user's identity?"
- ✅ **YES**

**Question 3:** "Do you or your third-party partners use this data for tracking?"
- ❌ **NO**

Click **"Next"**

---

#### **Physical Address**

**Question 1:** "How is this data used?"
- ✅ **App Functionality** (for user profile)

**Question 2:** "Is this data linked to the user's identity?"
- ✅ **YES**

**Question 3:** "Do you or your third-party partners use this data for tracking?"
- ❌ **NO**

Click **"Next"**

---

#### **Other User Content** (Farm Data)

**Question 1:** "How is this data used?"
- ✅ **App Functionality** (core feature - farm management)
- ✅ **Analytics** (anonymized for benchmark comparisons)
- ✅ **Product Personalization** (to show user their data)

**Question 2:** "Is this data linked to the user's identity?"
- ✅ **YES** (farm data belongs to specific user)

**Question 3:** "Do you or your third-party partners use this data for tracking?"
- ❌ **NO**

Click **"Next"**

---

#### **User ID**

**Question 1:** "How is this data used?"
- ✅ **App Functionality** (Firebase authentication)
- ✅ **Analytics** (to track app usage patterns)

**Question 2:** "Is this data linked to the user's identity?"
- ✅ **YES** (User ID identifies the user)

**Question 3:** "Do you or your third-party partners use this data for tracking?"
- ❌ **NO** (User ID is internal, not used for cross-app tracking)

Click **"Next"**

---

### Step 5: Review and Publish

1. You'll see a summary of all your selections
2. Review to make sure everything is accurate
3. Click **"Publish"** (or "Save")

**You should see:**
- ✅ Email Address → App Functionality, Developer Communications → Linked to User → Not Used for Tracking
- ✅ Name → App Functionality, Product Personalization → Linked to User → Not Used for Tracking
- ✅ Phone Number → App Functionality, Developer Communications → Linked to User → Not Used for Tracking
- ✅ Physical Address → App Functionality → Linked to User → Not Used for Tracking
- ✅ Other User Content → App Functionality, Analytics, Product Personalization → Linked to User → Not Used for Tracking
- ✅ User ID → App Functionality, Analytics → Linked to User → Not Used for Tracking

---

## ✅ Verification Checklist

After completing both tasks:

### Task 1: Privacy Policy URL
- [ ] URL added to App Store Connect → App Information
- [ ] URL is accessible (click it from App Store Connect)
- [ ] URL uses HTTPS
- [ ] Privacy policy displays correctly
- [ ] Contact information is correct (NexAir Industries, paul@nexair.io)

### Task 2: Privacy Questionnaire
- [ ] All collected data types selected
- [ ] No data types selected that you DON'T collect
- [ ] Each data type configured with correct usage
- [ ] All data types marked as "Linked to User" (YES)
- [ ] All data types marked as "Not Used for Tracking" (NO)
- [ ] Summary reviewed and published

---

## 🚨 Common Mistakes to Avoid

### ❌ **Don't Select Data You Don't Collect**
If you select "Location" but don't actually collect it → Rejection

### ❌ **Don't Mark as "Not Linked to User" If It Is**
All HerdWorks data is linked to user accounts → Always select "YES"

### ❌ **Don't Select "Used for Tracking" Unless You Do**
HerdWorks doesn't track users across apps → Always select "NO"

### ❌ **Don't Forget Firebase Data**
Firebase collects User ID and some analytics → Must disclose this

### ❌ **Don't Use HTTP for Privacy Policy**
Must be HTTPS → Your GitHub Pages URL already is ✅

---

## 📊 What This Achieves

**Removes 2 Critical Blockers:**
1. ✅ Privacy Policy URL requirement (Apple can verify your privacy practices)
2. ✅ Privacy Questionnaire (App Store displays this to users before download)

**App Store Readiness Progress:**
- ✅ Store memory leak fixed
- ✅ Accessibility support
- ✅ Account deletion
- ✅ Privacy policy hosted
- ✅ Privacy URL added to App Store Connect ← Task 1
- ✅ Privacy questionnaire completed ← Task 2
- ⏳ App metadata (next)
- ⏳ Screenshots (next)
- ⏳ Demo account (next)

**Overall Progress:** ~80% complete! 🎉

---

## 🎯 After Completing These Tasks

Once both tasks are done, the next priorities are:

1. **App Store Metadata** (4-6 hours)
   - App description
   - Keywords
   - Screenshots (3-10 required)
   - App icon verification

2. **Demo Account** (30 minutes)
   - Create test account with sample data
   - Document credentials for App Review

3. **Final Testing** (2-3 hours)
   - VoiceOver testing
   - Device testing
   - Build and upload

**We're very close to submission!** 🚀

---

## 💡 Pro Tips

### For Privacy Policy URL:
- **Bookmark your GitHub Pages URL** - You'll need it again
- **Test in incognito mode** - Simulates how Apple sees it
- **Check on mobile** - Open on iPhone to verify it's readable

### For Privacy Questionnaire:
- **Be honest** - Apple tests apps and will reject if answers don't match behavior
- **When in doubt, disclose** - Better to over-disclose than under-disclose
- **Save often** - Click "Save" as you go (it doesn't auto-save)
- **Review before publishing** - Double-check the summary

### General:
- **Keep App Store Connect open** - You'll be back here for metadata
- **Take screenshots** - Document what you selected for future reference
- **Don't rush** - Take time to read each question carefully

---

## 📞 Need Help?

**Stuck on Privacy Policy URL?**
- Verify GitHub Pages is enabled: Settings → Pages
- Check file is named `index.html` in `/docs` folder
- Wait 5 minutes if just enabled
- Try URL in private browser

**Stuck on Privacy Questionnaire?**
- Refer to `PRIVACY_POLICY.md` for data collection details
- When unsure, use answers provided in this guide
- Save progress and come back if needed
- Apple doesn't explain options well - this guide is detailed for you

**Questions?**
- Review `PRIVACY_POLICY_SETUP.md` for additional context
- Check `APP_STORE_READINESS.md` for overall plan
- Firebase privacy info: https://firebase.google.com/support/privacy

---

## ⏱️ Time Estimate

**Task 1 (Privacy URL):** 3-5 minutes
- Navigate to App Information: 1 min
- Enter URL and save: 1 min
- Verify it works: 1 min

**Task 2 (Privacy Questionnaire):** 25-35 minutes
- Navigate to App Privacy: 2 min
- Select data types: 5 min
- Configure 6 data types (5 min each): 25 min
- Review and publish: 3 min

**Total:** 30-40 minutes

---

## ✅ Ready to Start!

Follow the steps above in order. Both tasks are in App Store Connect, so keep that tab open.

**Start with Task 1 (Privacy URL)** - It's quick and easy!

Let me know when you've completed both tasks and I'll guide you through the next steps (App Store metadata and screenshots). 🎯

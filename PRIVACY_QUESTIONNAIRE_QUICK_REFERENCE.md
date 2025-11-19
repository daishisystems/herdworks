# Privacy Questionnaire - Quick Reference Card

**Use this while filling out App Store Connect App Privacy section**

---

## 📋 Data Types to SELECT

Copy this list and check off as you go:

- [ ] **Contact Info:**
  - [ ] Email Address
  - [ ] Name
  - [ ] Phone Number
  - [ ] Physical Address

- [ ] **User Content:**
  - [ ] Other User Content

- [ ] **Identifiers:**
  - [ ] User ID

**Total:** 6 data types

---

## 🚫 Data Types to SKIP (Do NOT Select)

- ❌ Precise Location
- ❌ Coarse Location
- ❌ Photos or Videos
- ❌ Payment Info
- ❌ Device ID (for advertising)
- ❌ Contacts
- ❌ Purchase History
- ❌ Everything else not listed above

---

## 🎯 Answer Pattern (For ALL Data Types)

### Question 1: "How is this data used?"

**Email Address:**
- ✅ App Functionality
- ✅ Developer Communications

**Name:**
- ✅ App Functionality
- ✅ Product Personalization

**Phone Number:**
- ✅ App Functionality
- ✅ Developer Communications

**Physical Address:**
- ✅ App Functionality

**Other User Content (Farm Data):**
- ✅ App Functionality
- ✅ Analytics
- ✅ Product Personalization

**User ID:**
- ✅ App Functionality
- ✅ Analytics

---

### Question 2: "Is this data linked to the user's identity?"

**For ALL 6 data types:**
- ✅ **YES** (all data is tied to user accounts)

---

### Question 3: "Used for tracking?"

**For ALL 6 data types:**
- ❌ **NO** (HerdWorks doesn't track users across apps)

---

## ✅ Final Summary Check

Your summary should show:

```
EMAIL ADDRESS
├─ Used for: App Functionality, Developer Communications
├─ Linked to User: YES
└─ Used for Tracking: NO

NAME
├─ Used for: App Functionality, Product Personalization
├─ Linked to User: YES
└─ Used for Tracking: NO

PHONE NUMBER
├─ Used for: App Functionality, Developer Communications
├─ Linked to User: YES
└─ Used for Tracking: NO

PHYSICAL ADDRESS
├─ Used for: App Functionality
├─ Linked to User: YES
└─ Used for Tracking: NO

OTHER USER CONTENT
├─ Used for: App Functionality, Analytics, Product Personalization
├─ Linked to User: YES
└─ Used for Tracking: NO

USER ID
├─ Used for: App Functionality, Analytics
├─ Linked to User: YES
└─ Used for Tracking: NO
```

---

## 🚨 Red Flags (If You See These, STOP)

**WRONG:**
- ❌ Any "Used for Tracking: YES" → Should be NO for all
- ❌ Any "Linked to User: NO" → Should be YES for all
- ❌ Selected "Location" → We don't collect this
- ❌ Selected "Photos" → We don't collect this
- ❌ More than 6 data types → You selected too many
- ❌ Less than 6 data types → You missed something

**If you see any of these, go back and fix them!**

---

## 💡 Quick Tips

1. **Save Often** - Click "Save" after each data type
2. **Read Carefully** - Questions are confusing, take your time
3. **When in Doubt** - Use the answers in this guide
4. **Can't Find Something?** - Check the full guide: `APP_STORE_CONNECT_SETUP_GUIDE.md`

---

## ⏱️ Expected Time

- Selecting 6 data types: ~5 minutes
- Configuring 6 data types: ~25 minutes
- Review and publish: ~3 minutes
- **Total: ~30 minutes**

---

**Print or keep this open while filling out App Store Connect!** 📋

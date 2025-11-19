# GitHub Pages Setup for Privacy Policy

This guide will help you publish your privacy policy to GitHub Pages for free hosting.

---

## 📁 What's in the `docs` Folder?

- **index.html** - Your privacy policy (hosted at `https://yourusername.github.io/herdworks/`)
- This file (README.md) - Setup instructions

---

## 🚀 Quick Setup (5 Minutes)

### Step 1: Enable GitHub Pages

1. Go to your repository on GitHub: **https://github.com/daishisystems/herdworks**
2. Click **Settings** (top navigation)
3. Scroll down to **Pages** (left sidebar under "Code and automation")
4. Under "Build and deployment":
   - **Source:** Deploy from a branch
   - **Branch:** Select `main` (or your default branch)
   - **Folder:** Select `/docs`
   - Click **Save**

### Step 2: Wait for Deployment (2-5 minutes)

GitHub will automatically build and deploy your site. You'll see:
- "Your site is ready to be published at..."
- Then "Your site is live at https://daishisystems.github.io/herdworks/"

### Step 3: Verify It Works

1. Click the URL shown in GitHub Pages settings
2. You should see your privacy policy page
3. Test on mobile and desktop browsers

**Your Privacy Policy URL will be:**
```
https://daishisystems.github.io/herdworks/
```

---

## 📋 Next Steps After Publishing

### 1. Add Privacy Policy URL to App Store Connect

1. Log in to **App Store Connect**
2. Navigate to your app → **App Information**
3. Find "Privacy Policy URL" field
4. Enter: `https://daishisystems.github.io/herdworks/`
5. Click **Save**

### 2. Update Contact Information (Optional)

If you need to change the support email or address:

1. Edit `docs/index.html`
2. Find the "Contact Us" section (around line 304)
3. Update email or address as needed:
   ```html
   <li><strong>Email:</strong> <a href="mailto:your-email@example.com">your-email@example.com</a></li>
   <li><strong>Address:</strong> Your Business Address, City, Country</li>
   ```
4. Commit and push changes
5. GitHub Pages will automatically redeploy (takes 1-2 minutes)

### 3. Test the URL

Before submitting to App Store:
- Open the URL in a browser
- Verify all text is readable
- Check on mobile (Safari on iPhone)
- Ensure no 404 errors
- Verify HTTPS works (required by Apple)

---

## 🔄 Updating the Privacy Policy

To update your privacy policy in the future:

1. Edit `docs/index.html`
2. Update the "Last Updated" date (line 326):
   ```html
   <strong>Last Updated:</strong> January 19, 2025
   ```
3. Commit and push to main branch
4. GitHub Pages will auto-deploy within 1-2 minutes

**Note:** Keep `privacy-policy.html` and `docs/index.html` in sync!

---

## 🌐 Custom Domain (Optional)

Want to use your own domain like `https://herdworks.app/privacy-policy`?

### Requirements:
- Own domain registered (e.g., herdworks.app)
- DNS access to add CNAME records

### Setup:
1. Add a file named `CNAME` in the `docs` folder:
   ```
   herdworks.app
   ```
2. In your DNS settings, add a CNAME record:
   - **Type:** CNAME
   - **Name:** www (or @)
   - **Value:** daishisystems.github.io
3. In GitHub Pages settings:
   - Enter custom domain: `herdworks.app`
   - Wait for DNS check (can take up to 24 hours)
   - Enable "Enforce HTTPS"

**Then your URL becomes:** `https://herdworks.app/`

---

## ⚠️ Troubleshooting

### Issue: "404 - There isn't a GitHub Pages site here"

**Fix:**
1. Check that GitHub Pages is enabled in Settings → Pages
2. Ensure branch is set to `main` and folder to `/docs`
3. Wait 2-5 minutes after enabling
4. Clear browser cache and try again

### Issue: "Privacy policy URL is not accessible"

**Fix:**
1. Verify the URL works in incognito/private browser
2. Check that the repository is **public** (or Pages enabled for private repos)
3. Ensure file is named `index.html` (not `privacy-policy.html`)
4. Try the full URL: `https://daishisystems.github.io/herdworks/`

### Issue: "Changes not showing up"

**Fix:**
1. Push commits to main branch
2. Wait 1-2 minutes for deployment
3. Hard refresh browser (Ctrl+Shift+R or Cmd+Shift+R)
4. Check the Actions tab on GitHub to see deployment status

---

## 📊 Current Status

**Branch:** This setup is on branch `claude/privacy-policy-hosting-01BnbW7cUodc1EirbFiA4yxr`

**Files Updated:**
- ✅ `docs/index.html` - Privacy policy for GitHub Pages
- ✅ `privacy-policy.html` - Source privacy policy (keep in sync)
- ✅ `PRIVACY_POLICY.md` - Markdown version (documentation)

**Next Actions:**
1. Merge this branch to `main`
2. Enable GitHub Pages in repository settings
3. Verify URL works
4. Add URL to App Store Connect

---

## 🎯 Verification Checklist

Before submitting to App Store, verify:

- [ ] Privacy policy is accessible at GitHub Pages URL
- [ ] URL loads over HTTPS (padlock in browser)
- [ ] Page loads on mobile (test in Safari on iPhone)
- [ ] Contact information is correct
- [ ] Support email is valid and monitored
- [ ] "Last Updated" date is accurate
- [ ] URL added to App Store Connect → App Information
- [ ] URL tested in App Store Connect (they verify it's accessible)

---

## 📞 Support

If you have questions:
- **GitHub Pages Docs:** https://docs.github.com/en/pages
- **GitHub Status:** https://www.githubstatus.com/ (check if Pages is down)

---

**Ready to enable GitHub Pages!** 🚀

Follow Step 1 above to get started. Your privacy policy will be live in under 5 minutes.

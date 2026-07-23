# Legal Documents Setup Instructions

## 🎯 Overview

You now have a **Help tab** in your app with links to legal documents. This guide shows how to make those links work.

---

## 📚 What's Ready

### In Your App:
✅ Help tab with 6 sections:
- Privacy Policy link
- Terms of Service link
- Food Disclaimer link
- Contact Support
- FAQ (local)
- About (local)

### Documents Created:
- `PRIVACY-POLICY.md`
- `TERMS-OF-SERVICE.md`
- `FOOD-DISCLAIMER.md`
- `LEGAL-COMPLIANCE-CHECKLIST.md`

---

## 🔧 Setup Steps

### Step 1: Choose Hosting

**Option A: GitHub Pages (FREE)** ⭐ Recommended
- Free forever
- Easy setup
- Professional URLs

**Option B: Your Website**
- If you have pikme.app domain
- Any hosting (Vercel, Netlify, etc.)

**Option C: Google Sites (FREE)**
- Simple alternative
- No coding needed

**Option D: Notion (FREE)**
- Publish as public pages
- Share URLs in app

---

## Option A: GitHub Pages Setup (Recommended)

### Step 1: Create GitHub Repo

1. Go to https://github.com/new
2. Create repo named: `pikme-legal`
3. Add `.gitignore` for Markdown
4. Make it **Public**

### Step 2: Add Legal Documents

1. Clone the repo:
```bash
git clone https://github.com/YOUR_USERNAME/pikme-legal.git
cd pikme-legal
```

2. Copy your legal files:
```bash
cp ../PikMe-expo/PRIVACY-POLICY.md ./privacy.md
cp ../PikMe-expo/TERMS-OF-SERVICE.md ./terms.md
cp ../PikMe-expo/FOOD-DISCLAIMER.md ./disclaimer.md
```

3. Create `index.html`:
```html
<!DOCTYPE html>
<html>
<head>
    <title>PikMe Legal Documents</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            line-height: 1.6;
            color: #333;
        }
        h1 { color: #2e7d32; }
        a { color: #2e7d32; text-decoration: none; }
        a:hover { text-decoration: underline; }
        .notice {
            background: #FFF9E6;
            border: 2px solid #FF6B35;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
    </style>
</head>
<body>
    <h1>PikMe Legal Documents</h1>
    <div class="notice">
        <strong>⚠️ Important:</strong> PikMe is an AI recommendation tool. 
        Always verify nutritional info and allergens with restaurants.
    </div>
    
    <h2>Documents</h2>
    <ul>
        <li><a href="./privacy.html">Privacy Policy</a></li>
        <li><a href="./terms.html">Terms of Service</a></li>
        <li><a href="./disclaimer.html">Food Disclaimer</a></li>
    </ul>
</body>
</html>
```

4. Commit & push:
```bash
git add .
git commit -m "Add legal documents"
git push origin main
```

### Step 3: Enable GitHub Pages

1. Go to repo Settings
2. Scroll to "GitHub Pages"
3. Source: `main` branch
4. Click "Save"
5. Wait ~1 minute for deployment

### Step 4: Get URLs

Your documents will be at:
- `https://YOUR_USERNAME.github.io/pikme-legal/privacy.html`
- `https://YOUR_USERNAME.github.io/pikme-legal/terms.html`
- `https://YOUR_USERNAME.github.io/pikme-legal/disclaimer.html`

---

## Option B: Custom Domain (pikme.app)

If you own `pikme.app`:

### Using Vercel (Recommended)

1. Connect your repo to Vercel
2. Push documents to GitHub
3. Vercel auto-deploys
4. Set custom domain: pikme.app
5. URLs become:
   - `https://pikme.app/privacy`
   - `https://pikme.app/terms`
   - `https://pikme.app/disclaimer`

### Vercel Setup:
```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel

# Set custom domain in Vercel dashboard
```

---

## Option C: Simple Website

If you have web hosting (Bluehost, GoDaddy, etc.):

1. Create `legal/` folder on server
2. Upload markdown files
3. URLs: `https://pikme.app/legal/privacy`

---

## 🔗 Update Your App

Once you have your URLs, update `app/(tabs)/help.tsx`:

```typescript
const LEGAL_LINKS = {
  privacy: 'https://YOUR_ACTUAL_URL/privacy',
  terms: 'https://YOUR_ACTUAL_URL/terms',
  disclaimer: 'https://YOUR_ACTUAL_URL/disclaimer',
  support: 'mailto:support@pikme.app',
};
```

---

## 📱 Update App Stores

### Apple App Store Connect

1. Go to App Store Connect
2. Select your app
3. App Information → Privacy Policy
4. Enter: `https://YOUR_URL/privacy`
5. Save

### Google Play Console

1. Go to Google Play Console
2. Select your app
3. App content → Privacy Policy
4. Enter: `https://YOUR_URL/privacy`
5. Save

---

## ✅ Testing

### Test Links in App

1. Run app: `npm start`
2. Tap "Help" tab
3. Tap each link
4. Verify docs open in browser

### Test URLs Directly

Visit each URL in browser:
- [ ] `https://YOUR_URL/privacy` - Opens
- [ ] `https://YOUR_URL/terms` - Opens
- [ ] `https://YOUR_URL/disclaimer` - Opens

---

## 🚀 Before App Store Submission

Checklist:
- [ ] Legal documents customized with your info
- [ ] Documents hosted online
- [ ] All links tested and working
- [ ] Privacy Policy URL in App Store
- [ ] Terms linked in app description
- [ ] Help tab visible in app
- [ ] Support email works
- [ ] No broken links

---

## 📝 Document Customization

In all three documents, replace:

```markdown
[Your Company Name]     → PikMe Inc.
[support email]         → support@pikme.app
[privacy email]         → privacy@pikme.app
[legal email]           → legal@pikme.app
[dpo email]            → dpo@pikme.app
[Your Jurisdiction]     → United States, California (or your location)
```

---

## 🎯 Final Step-by-Step

### Quickest Path (GitHub Pages):

1. Create GitHub repo: `pikme-legal`
2. Add 3 markdown files + index.html
3. Enable GitHub Pages
4. Get GitHub Pages URL
5. Update `help.tsx` with URLs
6. Test in app
7. Update app store listings

**Time: ~15 minutes**

---

## 💡 Tips

- GitHub Pages is free and professional
- Always test links before submitting to app stores
- Keep documents synchronized
- Update documents when app features change
- Back up documents (git commits)

---

## 🆘 Troubleshooting

**Links don't work:**
- Check URL spelling
- Make sure domain has HTTPS (not HTTP)
- Clear app cache: `expo start --clear`

**GitHub Pages not showing:**
- Check repo is Public
- Wait 2-3 minutes after pushing
- Check Settings → Pages is enabled

**Documents not displaying:**
- Convert markdown to HTML
- Use markdown viewer browser extension
- Or export PDF from markdown

---

## 📧 Support Email Setup

Create email for support:

**Option 1: Gmail**
- Create: support@pikme.app
- Forward to your email
- Replies show as support@pikme.app

**Option 2: Company Email**
- If you have business email
- Use that directly

**Option 3: Form**
- Use Formspree or Netlify Forms
- Replies go to your email

---

## 🎉 You're Ready!

Once you complete these steps:
✅ Help tab fully functional
✅ Legal docs publicly accessible
✅ App store compliant
✅ Ready for submission

---

**Questions?** See LEGAL-COMPLIANCE-CHECKLIST.md for more details.

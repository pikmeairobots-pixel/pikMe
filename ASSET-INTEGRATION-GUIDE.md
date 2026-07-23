# PikMe Brand Asset Integration Guide

## ✅ What's Been Done

### 1. **Brand Theme System Created**
- ✅ `src/constants/brandTheme.ts` - Complete design system
- ✅ Color palette with BRAND_COLORS
- ✅ Typography scales
- ✅ Spacing system
- ✅ Shadow definitions

### 2. **App Colors Updated**
- ✅ Menu Item Card uses brand colors
- ✅ Menu Mentor chat page uses brand colors
- ✅ Buttons use `BRAND_COLORS.primary` (#2e7d32)
- ✅ All interactive elements use brand theme

### 3. **Brand Assets Created**
- ✅ `brand-assets/PikMe-Logo.svg` - Full logo
- ✅ `brand-assets/PikMe-Icon.svg` - App icon
- ✅ `brand-assets/Splash-Screen.svg` - Loading screen
- ✅ `brand-assets/BRAND-GUIDELINES.md` - Complete design system

---

## 🔄 Converting SVGs to PNGs

### Option 1: Online Converter (Quickest)
1. Visit **https://cloudconvert.com/svg-to-png**
2. Upload each SVG file
3. Download PNG files
4. Place in `assets/` folder

### Option 2: Using ImageMagick (Command Line)
```bash
# Install ImageMagick if needed
# Then run:

convert -density 300 brand-assets/PikMe-Icon.svg -resize 192x192 assets/icon.png
convert -density 300 brand-assets/Splash-Screen.svg -resize 1080x1920 assets/splash-icon.png
```

### Option 3: In Figma
1. Import SVG to Figma
2. Export at required sizes
3. Save as PNG

---

## 📱 Required Asset Sizes

### App Icon (Main)
| Platform | Size | Format |
|----------|------|--------|
| iOS 1x | 180x180 | PNG |
| iOS 2x | 120x120 | PNG |
| iOS 3x | 60x60 | PNG |
| Android | 192x192 | PNG |
| Web | 512x512 | PNG |

**File:** `assets/icon.png` (1080x1920 will auto-scale)

### Splash Screen
| Device | Size | Format |
|--------|------|--------|
| iPhone | 1080x1920 | PNG |
| iPad | 2160x1620 | PNG |
| Android | 1080x1920 | PNG |

**File:** `assets/splash-icon.png`

### Android Adaptive Icon
```
assets/android-icon-foreground.png (1080x1080, transparent)
assets/android-icon-background.png (1080x1080, solid color: #E8F5E9)
```

---

## 🚀 Implementation Steps

### Step 1: Convert Assets
1. Convert `PikMe-Icon.svg` → `icon.png` (1080x1080)
2. Convert `Splash-Screen.svg` → `splash-icon.png` (1080x1920)

### Step 2: Place Files
```
assets/
├── icon.png
├── splash-icon.png
├── android-icon-foreground.png
├── android-icon-background.png
└── favicon.png
```

### Step 3: Update `app.config.js`
Already configured to use these files:
```javascript
{
  icon: './assets/icon.png',
  splash: {
    image: './assets/splash-icon.png',
    backgroundColor: '#ffffff',
  },
  android: {
    adaptiveIcon: {
      foregroundImage: './assets/android-icon-foreground.png',
      backgroundImage: './assets/android-icon-background.png',
    },
  },
}
```

### Step 4: Test Locally
```bash
npm start
# Press 'i' for iOS or 'a' for Android
```

---

## 🎨 Brand Color Usage Throughout App

### Primary Colors Used
- **Buttons:** `BRAND_COLORS.primary` (#2e7d32)
- **Hover/Pressed:** `BRAND_COLORS.primaryDark` (#1b4d1b)
- **Light backgrounds:** `BRAND_COLORS.primaryLight` (#E8F5E9)

### Components Updated
- ✅ Menu Item Card - "Should I get this?" button
- ✅ Menu Mentor - Question chips & close button
- ✅ Loading spinners - Brand green color
- ✅ All interactive elements

### To Update Other Components
```typescript
import { BRAND_COLORS } from '../../src/constants/brandTheme';

// Use in styles
backgroundColor: BRAND_COLORS.primary,
color: BRAND_COLORS.text.primary,
borderColor: BRAND_COLORS.primaryLight,
```

---

## 📋 Checklist

- [ ] Convert SVGs to PNGs (cloudconvert.com or Figma)
- [ ] Place PNG files in `assets/` folder
- [ ] Run `npm start` to test
- [ ] Verify icon appears on home screen
- [ ] Verify splash screen shows on app launch
- [ ] Test on both iOS and Android (if possible)

---

## 🎯 Next Steps

After converting assets:
1. **Test locally** - Run `npm start` and check icon/splash
2. **Build APK** - `eas build --platform android`
3. **Build IPA** - `eas build --platform ios`
4. **Update app store** - Upload new assets to stores

---

## 💡 Pro Tips

- **Icon Design:** Make sure icon looks good at small sizes (home screen)
- **Splash Screen:** Test on various phone sizes to ensure no cutoff
- **Color Accuracy:** Convert at high DPI (300px) for crisp results
- **Safe Area:** Keep important content away from edges

---

## 🔗 Resources

- SVG to PNG: https://cloudconvert.com/svg-to-png
- Figma: https://figma.com
- Expo Asset Guide: https://docs.expo.dev/build-reference/app-icons-and-splash-screens/
- ImageMagick: https://imagemagick.org/

---

**Status:** Ready for asset conversion  
**Last Updated:** 2026-06-17

# PikMe Brand Guidelines

## 🎨 Brand Identity

### Logo Concept
**Visual Elements:**
- Fork (personalization, choice)
- Heart (preference, love of food)
- Checkmark (selection, the "pick")
- Circular form (community, wholeness)

**Philosophy:** PikMe empowers users to choose meals that match their unique preferences—combining practical selection with personal passion.

---

## 🎯 Color Palette

### Primary Colors
| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| **PikMe Green** | `#2e7d32` | 46, 125, 50 | Primary action, buttons, highlights |
| **Dark Green** | `#1b4d1b` | 27, 77, 27 | Hover states, deep accents |
| **Light Green** | `#E8F5E9` | 232, 245, 233 | Backgrounds, soft fills |
| **Accent Red** | `#FF6B6B` | 255, 107, 107 | Heart icon, positive signals |
| **Success Green** | `#4CAF50` | 76, 175, 80 | Checkmarks, confirmations |

### Neutral Colors
| Name | Hex | Usage |
|------|-----|-------|
| **Black** | `#1a1a1a` | Text, primary content |
| **Dark Gray** | `#333333` | Secondary text |
| **Medium Gray** | `#888888` | Tertiary text, borders |
| **Light Gray** | `#f0f0f0` | Backgrounds, dividers |
| **White** | `#ffffff` | Canvas, cards |

---

## 🔤 Typography

### Font Stack
```
Primary: "SF Pro Display" / "Helvetica Neue" / sans-serif
Secondary: "Inter" / "San Francisco" / sans-serif
Monospace: "Courier New" (for nutrition data)
```

### Type Scales
| Element | Size | Weight | Usage |
|---------|------|--------|-------|
| **H1 (Page Title)** | 24px | 800 | Main headings |
| **H2 (Section)** | 18px | 700 | Section titles |
| **H3 (Card Title)** | 16px | 700 | Card/item titles |
| **Body** | 15px | 400 | Regular content |
| **Small** | 13px | 500 | Labels, captions |
| **Tiny** | 12px | 400 | Metadata, hints |

### Line Height
- Headings: 1.1x
- Body: 1.5x
- Captions: 1.4x

---

## 🎭 Visual Style

### Spacing System
- **Base Unit:** 4px
- **Common Spacings:** 8px, 12px, 16px, 20px, 24px, 32px, 40px

### Border Radius
- **Buttons/Pills:** 12px - 20px
- **Cards:** 16px
- **Large elements:** 24px
- **Full circle:** 50% (avatars)

### Shadows
- **Subtle:** `0px 2px 4px rgba(0,0,0,0.07)`
- **Medium:** `0px 4px 12px rgba(0,0,0,0.1)`
- **Elevated:** `0px 8px 24px rgba(0,0,0,0.12)`

---

## 📱 Asset Sizes

### App Icon
- **iOS:** 180x180px (1x), 120x120px (2x)
- **Android:** 192x192px (mdpi), 384x384px (xxxhdpi)
- **Web:** 512x512px

### Splash Screen
- **Mobile:** 1080x1920px (9:16 ratio)
- **Tablet:** 2160x1620px (4:3 ratio)

### Social Media
- **Instagram Profile:** 320x320px
- **Twitter Header:** 1500x500px
- **Facebook Cover:** 820x312px

---

## 🎨 Design Patterns

### Button States
- **Default:** PikMe Green background, white text
- **Hover:** Dark Green background (darken 10%)
- **Pressed:** 95% scale, haptic feedback
- **Disabled:** 50% opacity, no interactions

### Card Design
- **Background:** White (#fff)
- **Border Radius:** 16px
- **Shadow:** Subtle (elevation: 3)
- **Padding:** 16px
- **Dividers:** Light Gray (#f0f0f0)

### Badges/Chips
- **Good/Positive:** Light Green background + Green text
- **Warning:** Light Orange background + Orange text
- **Neutral:** Light Gray background + Gray text

---

## ✨ Animation Guidelines

### Transitions
- **Button press:** 100ms spring
- **Modal entrance:** 300ms fade + slide
- **List items:** 100ms stagger between items
- **Loading states:** Continuous shimmer (800ms cycle)

### Microinteractions
- **Button tap:** Scale to 95%, haptic feedback
- **Save action:** Scale + color change
- **Chip selection:** Fade + slight scale
- **Response text:** Staggered fade-in (50ms between lines)

---

## 🌐 Usage Examples

### On Light Background
- Use PikMe Green (#2e7d32) for primary elements
- Use Dark Gray (#333) for text
- Use Light Gray (#f0f0f0) for containers

### On Dark Background (if needed)
- Use white text
- Use Light Green (#E8F5E9) for accents
- Use Light Gray for secondary elements

### Color Combinations (Do's & Don'ts)
✅ Green + White + Light Gray  
✅ Green + Heart Red (accent only)  
✅ Dark Gray + Light Green backgrounds  
❌ Red on Green (too vibrant)  
❌ Multiple accent colors competing  

---

## 📋 Brand Voice

**Tone:** Friendly, helpful, modern, encouraging  
**Personality:** Your personal food guide (knowledgeable but approachable)  
**Avoid:** Corporate jargon, overly casual slang, technical terms

### Example Copy
- ✅ "Find meals made for you"
- ✅ "Your personal menu guide"
- ✅ "What looks good today?"
- ❌ "AI-powered recommendation algorithm"
- ❌ "Yo, hungry bro?"

---

## 🚀 Implementation

### In Figma
1. Create color library with hex codes above
2. Import SVG files (PikMe-Logo.svg, PikMe-Icon.svg)
3. Set up type styles using font stack
4. Create component library for:
   - Buttons (all states)
   - Cards
   - Chips
   - Badges
5. Build screens using components

### In Code
- Define colors as CSS/design tokens
- Use typography scales from above
- Apply shadow & radius values consistently
- Implement animation timings exactly

---

## 📦 Files Included

- `PikMe-Logo.svg` - Full logo with text
- `PikMe-Icon.svg` - App icon (no text)
- `BRAND-GUIDELINES.md` - This file

---

**Created:** 2026-06-17  
**Version:** 1.0  
**Status:** Ready for design system implementation

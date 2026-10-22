# App Store listing — copy and paste

Everything App Store Connect asks for on the 1.0 version page, in order. Character limits in brackets.

## App Information

- **Name** (30): `Rota: Shift Calendar`
- **Subtitle** (30): `Your shift pattern, forever`
- **Primary category:** Productivity
- **Secondary category:** Utilities
- **Content rights:** does not contain third-party content
- **Age rating:** answer None to every question → 4+

## Version 1.0

- **Promotional text** (170, optional): `Enter your pattern once. See every shift forever.`
- **Description** (4000):

```
Rota shows your repeating shift pattern as a calendar, so you can check your rota in seconds.

Enter your pattern once, for example 2 days, 2 nights, 4 off, and pick a date you know it started. Rota works out every shift from then on, forwards and backwards, and shows the month at a glance with each shift in its own colour.

Life rarely matches the rota. Tap any day to swap a shift, mark a holiday or sick day, or leave a note. Edited days show a dot so you always know what has changed.

Free:
• One pattern
• Month view with a summary of shifts, nights and days off
• Overrides and notes for any day
• Presets for common patterns: 4 on 4 off, 2D 2N 4 off, Mon to Fri, Continental, 3 on 3 off, 5 on 2 off / 5 on 3 off, plus your own custom cycle

One-time unlock, no subscription:
• Multiple patterns
• Your shifts in the Calendar app, kept up to date automatically
• A home screen widget showing today, your next shift and the week ahead

Rota has no accounts and no adverts. Everything stays on your phone.
```

- **Keywords** (100): `shift,rota,calendar,4 on 4 off,nurse,police,nights,pattern,roster,work`
- **Support URL:** `https://github.com/shandure/rota`
- **Marketing URL:** leave blank
- **Privacy Policy URL** (in App Privacy section): `https://github.com/shandure/rota/blob/main/PRIVACY.md`
- **Copyright:** `2026 <your legal name>`
- **Version:** `1.0`
- **What's New in This Version:** `First release.`

## Screenshots

Upload the files in `screenshots/iPhone_17_Pro_Max/` to the 6.9-inch slot, in this order:

1. month-light.png
2. builder-light.png
3. day-light.png
4. settings-light.png
5. paywall-light.png

Widget and Calendar screenshots are taken on your phone (Settings → Screenshot, or Side + Volume Up) and can be added to the same slot. Apple requires only the 6.9-inch set; smaller sizes are optional.

## App Review Information

- **Sign-in required:** No
- **Contact:** your name, phone, email
- **Notes:**

```
No account or sign-in. To test: tap Create pattern, choose the "2D 2N 4 off" preset, Save. Tap any day to set an override. The one-time in-app purchase "Unlock everything" (com.rotashift.rota.unlock) enables multiple patterns, the Calendar export in Settings and the home screen widget. Calendar access is requested only when "Add shifts to Calendar" is turned on, and the app writes only to a calendar it creates itself.
```

## App Privacy (questionnaire)

If a PostHog key is configured in the build:

- Data collected: **Usage Data → Product Interaction**. Used for Analytics. **Not linked to the user's identity.** Not used for tracking.
- Everything else: not collected.

If no PostHog key is configured: **Data Not Collected**.

## In-App Purchase review screenshot

On the "Unlock everything" purchase page, under Review Information, upload `screenshots/iPhone_17_Pro_Max/paywall-light.png`. Then click **Add for Review** on the purchase, and tick the purchase under "In-App Purchases and Subscriptions" on the 1.0 version page so it is reviewed with the app.

## Before you press Submit

- Paid Apps agreement shows Active under Business → Agreements.
- Build 9 or later selected on the version page.
- Five to ten shift workers have used a TestFlight build for about a week.

# App Store Connect Setup Guide

Complete guide for setting up your ZetaReps app with subscriptions in App Store Connect.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Create App in App Store Connect](#create-app-in-app-store-connect)
3. [Configure In-App Purchases](#configure-in-app-purchases)
4. [Set Up Subscription Group](#set-up-subscription-group)
5. [Create Subscription Products](#create-subscription-products)
6. [Configure Free Trial](#configure-free-trial)
7. [Testing Subscriptions](#testing-subscriptions)
8. [App Submission](#app-submission)

---

## Prerequisites

Before starting, ensure you have:
- [x] Active Apple Developer account ($99/year)
- [x] Xcode 15+ installed
- [x] Valid bundle identifier (e.g., `com.yourname.zetareps`)
- [x] Agreement, Tax, and Banking information completed in App Store Connect

---

## Create App in App Store Connect

### Step 1: Create New App

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Click "Apps" → "+" → "New App"
3. Fill in the details:
   - **Platform**: iOS
   - **Name**: ZetaReps
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: Select your bundle ID from dropdown
   - **SKU**: `zetareps001` (unique identifier for your reference)
   - **User Access**: Full Access

4. Click "Create"

### Step 2: Fill App Information

Navigate to your app → App Information:

- **Subtitle**: Track pushup workouts with set-based training & metrics
- **Category**:
  - Primary: Health & Fitness
  - Secondary: Lifestyle (optional)
- **Content Rights**: Check if app contains third-party content

---

## Configure In-App Purchases

### Step 1: Accept Paid Applications Agreement

1. Go to "Agreements, Tax, and Banking"
2. Accept "Paid Applications" agreement
3. Complete tax forms (W-9 for US, W-8BEN for international)
4. Add banking information for payments

**Note**: You MUST complete this before you can create in-app purchases.

### Step 2: Navigate to Subscriptions

1. Go to your app in App Store Connect
2. Select "Subscriptions" tab (under "Monetization")
3. Click "+" to create subscription group

---

## Set Up Subscription Group

### Step 1: Create Subscription Group

1. Click "Create Subscription Group"
2. Fill in details:
   - **Reference Name**: `Premium` (internal only, not shown to users)
   - **Group Display Name**: Leave blank (or add localized names if needed)

3. Click "Create"

### Important Notes:
- All subscription tiers MUST be in the same group
- Users can only subscribe to ONE product per group at a time
- Switching between tiers (monthly ↔ annual) is handled automatically

---

## Create Subscription Products

### Product 1: Monthly Subscription

1. Click "+" in your subscription group
2. Fill in the details:

**Product Information:**
- **Reference Name**: `Premium Monthly` (internal only)
- **Product ID**: `com.zetareps.premium.monthly`
  - ⚠️ **IMPORTANT**: Must match exactly what's in your code
  - Cannot be changed after creation
  - Must be unique across ALL apps in your account

**Subscription Duration:**
- Select: **1 month**

**Subscription Prices:**
- Click "Add Subscription Price"
- **Price**: $0.99 USD
- **Start Date**: Today's date
- Apple automatically converts to all other currencies

**Localizations:**
- Click "+" to add localization
- **Language**: English (U.S.)
- **Subscription Display Name**: `Premium Monthly`
  - This is what users see
- **Description**: `Unlock unlimited workout history, advanced metrics charts, all-time statistics, and full progress visualization`

**App Store Promotion (Optional):**
- **Promotional Image**: 1600×1200 px image showing premium features
- Leave blank for now, can add later

3. Click "Save"

### Product 2: Annual Subscription

1. Click "+" in your subscription group again
2. Fill in the details:

**Product Information:**
- **Reference Name**: `Premium Annual`
- **Product ID**: `com.zetareps.premium.annual`
  - ⚠️ Must match your code exactly

**Subscription Duration:**
- Select: **1 year**

**Subscription Prices:**
- **Price**: $5.99 USD
- This represents a 50% savings vs monthly ($11.88/year if billed monthly)

**Localizations:**
- **Language**: English (U.S.)
- **Subscription Display Name**: `Premium Annual`
- **Description**: `Get unlimited workout history, advanced metrics, and all premium features at the best value - save 50%`

3. Click "Save"

---

## Configure Free Trial

Both subscriptions should offer a 7-day free trial.

### For Monthly Subscription:

1. Open "Premium Monthly" product
2. Scroll to "Subscription Offers"
3. Click "Create Offer" → "Introductory Offer"
4. Select:
   - **Offer Type**: Free
   - **Duration**: 7 days
5. **Eligibility**:
   - ☑️ New Subscribers
   - ☐ Returning Subscribers (leave unchecked)
   - ☐ Existing Subscribers (leave unchecked)
6. Click "Save"

### For Annual Subscription:

1. Repeat the same process for "Premium Annual"
2. **Offer Type**: Free
3. **Duration**: 7 days
4. Same eligibility settings

### Important Free Trial Rules:

- Users can only use free trial ONCE per Apple ID
- Free trial starts immediately upon subscribing
- User is charged automatically after 7 days
- User can cancel anytime during trial (no charge)
- Must clearly disclose trial terms in your app

---

## Testing Subscriptions

### Step 1: Create Sandbox Test Account

1. In App Store Connect, go to "Users and Access"
2. Click "Sandbox Testers" (left sidebar)
3. Click "+" to add new tester
4. Fill in details:
   - **Email**: Use a unique email (can be fake, but must be unique)
     - Example: `test1@zetareps.test`
   - **Password**: Create a strong password
   - **Country/Region**: United States
   - **First Name / Last Name**: Test User

5. Click "Invite"

**Important**:
- DO NOT use a real Apple ID for sandbox testing
- Sandbox accounts are for testing only
- You can create multiple test accounts

### Step 2: Configure Xcode for Testing

1. Open your project in Xcode
2. Select your target → "Signing & Capabilities"
3. Go to the scheme selector → "Edit Scheme"
4. Select "Run" → "Options" tab
5. **StoreKit Configuration**: Select `Configuration.storekit`

### Step 3: Test Locally (Without App Store Connect)

1. Build and run app in simulator or device
2. Complete a few workouts to reach 100 pushups (or modify limit for testing)
3. Tap "Upgrade to Premium"
4. Select a subscription plan
5. Click "Start 7-Day Free Trial"
6. You'll see a StoreKit testing sheet (not real App Store)
7. Click "Subscribe"
8. Verify premium features unlock (full history, all charts)

**Testing Scenarios:**
- ✅ Purchase monthly subscription
- ✅ Purchase annual subscription
- ✅ Restore purchases
- ✅ Cancel subscription
- ✅ Subscription expires after 7 days (accelerated in sandbox)
- ✅ Free limit enforcement (100 pushups)
- ✅ Locked state on home screen when limit reached

### Step 4: Test with Sandbox Account (Real Environment)

1. On your test device, sign out of App Store
2. In Settings → App Store → Sign In
3. Use your **sandbox test account** credentials
4. Run app from Xcode on device
5. Complete purchase flow
6. Enter sandbox credentials when prompted

**Sandbox Accelerated Timeframes:**
- 7-day trial → 5 minutes in sandbox
- 1 month subscription → 5 minutes
- 1 year subscription → 1 hour
- Renewals happen automatically (up to 6 renewals in sandbox)

---

## App Submission

### Step 1: Prepare App Metadata

In App Store Connect → your app → "App Information":

**App Privacy:**
1. Click "Edit" next to App Privacy
2. Add required disclosures:
   - **Health & Fitness**: Workout data (stored on device only, not collected)
   - **Identifiers**: None
   - **Usage Data**: None
   - **Diagnostics**: None

**Screenshots:**
- iPhone 6.7" Display: 2-4 required (1290×2796 px)
- Suggested screenshots:
  1. Home screen with bento grid and performance metrics
  2. Workout session in progress with rest timer
  3. History view with metrics charts
  4. Settings with fitness level recommendations
- Can use Xcode simulator to capture

**App Preview (Optional):**
- 15-30 second video showing app functionality
- Show: Starting workout → completing sets with rest timer → viewing metrics

**Description:**
```
Track your pushup progress with set-based training, performance metrics, and science-backed recommendations.

CORE FEATURES:
• Set-based workout tracking with rest timers
• Performance metrics: Consistency & Intensity scores (0-10)
• Smart notifications with flexible scheduling
• Science-based fitness level recommendations
• Calendar heatmap and streak tracking
• Personal records and achievements
• Difficulty rating for each workout

FREE FEATURES:
• 100 total pushups
• Set-based workout tracking
• Performance metrics
• Custom reminders
• 7-day calendar view
• Streak tracking

PREMIUM FEATURES:
• Unlimited workout history
• Advanced metrics charts with trends
• All-time statistics and analytics
• Full calendar and history access
• Complete progress visualization
• Export your data
• Priority support

SCIENCE-BACKED RECOMMENDATIONS:
Based on 8 authoritative fitness sources, choose your level:
• Beginner: 3 sets × 8 reps, 4 days/week
• Intermediate: 4 sets × 15 reps, 5 days/week
• Advanced: 5 sets × 30 reps, 6 days/week

FREE TRIAL:
Start with a 7-day free trial. Cancel anytime.

SUBSCRIPTION PRICING:
• $0.99/month
• $5.99/year (save 50%)

Subscriptions auto-renew unless cancelled 24 hours before period ends. Manage subscriptions in Settings.

All data stored locally on your device. No account required.

Privacy Policy: [your URL]
Terms of Service: [your URL]
```

**Keywords:**
```
pushups,workout,fitness,tracker,exercise,training,calisthenics,strength,gym,health
```

(Max 100 characters including commas)

**Promotional Text (Optional, 170 chars):**
```
Track pushup workouts with set-based training, performance metrics, and science-backed recommendations. Start with 7-day free trial!
```

### Step 2: App Review Information

**Sign-In Information:**
- Leave blank (no login required)

**Notes for Reviewer:**
```
ZetaReps is a pushup workout tracker with set-based training and performance metrics.

FREEMIUM MODEL:
• FREE: 100 total pushups, basic features
• PREMIUM: Unlimited history, advanced charts ($0.99/mo or $5.99/yr)

HOW TO TEST:

1. BASIC FEATURES (Free):
   - Launch app
   - Go to Settings → Try "Recommended Standards" mode
   - Select fitness level (Beginner/Intermediate/Advanced)
   - Tap "Start Workout" on Home screen
   - Complete sets with rest timer between each
   - Log workout with difficulty rating
   - View stats on Home: today's count, streak, performance metrics
   - Check History tab for charts (limited to weekly view when free)

2. PREMIUM SUBSCRIPTION:
   - To quickly trigger paywall: Complete 5-10 workouts until 100 total pushups reached
   - OR tap "Upgrade to Premium" in Settings
   - Subscribe using sandbox test account
   - Verify all charts unlock (Month/All Time views)
   - Test "Restore Purchases" button

3. NOTIFICATIONS:
   - Go to Settings → Enable Reminders
   - Grant notification permission
   - Configure schedule (Daily/Hourly/Custom Times)
   - Notifications are context-aware and respect rest days

SANDBOX TEST ACCOUNT:
Email: [provide test account email]
Password: [provide password]

All data stored locally using SwiftData. No server/network required except for StoreKit.

Performance metrics based on scientific research from 8 fitness sources.
```

**Contact Information:**
- Your email and phone number

**Demo Account (Optional):**
- Leave blank (no login required)

### Step 3: Submit for Review

1. Build and archive app in Xcode:
   - Product → Archive
   - Window → Organizer
   - Select archive → "Distribute App"
   - App Store Connect → Upload

2. Once processing completes (10-30 minutes), go to App Store Connect
3. Navigate to your app → "App Store" tab
4. Click "+" next to "iOS App"
5. Select your build from dropdown
6. Fill in "What's New in This Version":
   ```
   Initial release of ZetaReps!

   • Set-based pushup tracking
   • Performance metrics (Consistency & Intensity)
   • Science-backed recommendations
   • Smart notifications
   • Personal records and achievements
   • 7-day free trial for Premium features
   ```

7. Review all metadata
8. Click "Add for Review"
9. Click "Submit to App Store"

**Review Timeline:**
- Typical: 24-48 hours
- First submission with subscriptions: May take 2-5 days
- Apple will test your subscription flow and free trial
- Rejections are common for first submission - respond promptly

---

## Common Issues & Solutions

### Issue: "Product IDs don't match"
**Solution**: Verify product IDs in code exactly match App Store Connect:
- Check: `SubscriptionManager.swift` product IDs
- App Store: In-App Purchases → Product ID
- They must match character-for-character

### Issue: "Products not loading"
**Solution**:
1. Check bundle ID matches between Xcode and App Store Connect
2. Wait 2-4 hours after creating products (propagation delay)
3. Ensure "Agreement, Tax, Banking" is complete
4. Products must be in "Ready to Submit" state
5. Try deleting app and reinstalling

### Issue: "Free trial not showing"
**Solution**:
1. Verify introductory offer is configured for both products
2. Check eligibility settings (new subscribers only)
3. Test with fresh sandbox account (trials only work once per account)
4. Clear app data between tests

### Issue: "Sandbox purchase fails"
**Solution**:
1. Sign out of real App Store account on device completely
2. Delete app and clear data
3. Use valid sandbox test account
4. Ensure subscription products are "Ready to Submit"
5. Check Xcode console for StoreKit error messages

### Issue: "Rejected for metadata"
**Solution**:
- Add clear subscription terms in description
- Include pricing information ($0.99/mo, $5.99/yr)
- Add screenshots showing both free and premium features
- Provide privacy policy and terms of service URLs
- Clearly explain 100 pushup free limit

### Issue: "Rejected for functionality"
**Solution**:
- Test thoroughly before submission
- Ensure paywall appears correctly at 100 pushups
- Verify all premium features unlock after subscription
- Test "Restore Purchases" functionality
- Provide detailed testing steps in review notes

---

## Post-Launch Checklist

After approval:

- [ ] Monitor subscription analytics in App Store Connect
- [ ] Check "Sales and Trends" for revenue
- [ ] Review "Subscription Retention" metrics weekly
- [ ] Respond to user reviews mentioning subscriptions within 24 hours
- [ ] Test restore purchases on multiple devices
- [ ] Monitor for subscription-related support requests
- [ ] Track conversion rate from free to premium
- [ ] Analyze where users drop off in subscription flow

**Key Metrics to Track:**
- **Trial conversion rate**: % of trials that convert to paid (target: 8-12%)
- **Monthly churn**: % of subscribers who cancel (target: <50% annually)
- **ARPU**: Average revenue per user (target: $10-25 annually for freemium fitness)
- **LTV**: Lifetime value per subscriber (target: 3-5x annual subscription price)
- **Free-to-paid conversion**: % of users who hit 100 pushups and subscribe (target: 2-5%)

---

## Subscription Best Practices

### Pricing Strategy:
- ✅ Monthly at $0.99 is impulse-purchase territory
- ✅ Annual at $5.99 offers strong incentive (50% savings)
- ✅ 7-day trial gives users time to experience value
- ✅ 100 pushup free limit is achievement-based (better than time-based)

### Conversion Optimization:
- Show value frequently: Display premium features on History screen
- Make paywall contextual: Appears when user wants more data
- Highlight savings: Emphasize 50% discount on annual
- Social proof: Show number of premium users (if significant)
- Clear benefits: List specific features, not vague "premium access"

### Retention Strategies:
- Send engagement notifications to lapsed users
- Offer winback promotions after cancellation
- Add exclusive premium features over time
- Create achievement badges for long-term subscribers
- Consider annual-only exclusive features

---

## Additional Resources

**Apple Documentation:**
- [In-App Purchase Guide](https://developer.apple.com/in-app-purchase/)
- [StoreKit 2 Documentation](https://developer.apple.com/documentation/storekit)
- [Subscription Best Practices](https://developer.apple.com/app-store/subscriptions/)

**Testing Resources:**
- [Sandbox Testing Guide](https://developer.apple.com/documentation/storekit/in-app_purchase/testing_in-app_purchases)
- [Testing Auto-Renewable Subscriptions](https://developer.apple.com/documentation/storekit/in-app_purchase/testing_auto-renewable_subscriptions)

**App Store Connect:**
- [App Store Connect](https://appstoreconnect.apple.com/)
- [Analytics Dashboard](https://appstoreconnect.apple.com/analytics)
- [Sales and Trends](https://appstoreconnect.apple.com/trends)

**App Review Guidelines:**
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- Section 3.1.2: Subscriptions requirements

---

## Support

If you encounter issues:
1. Check Apple Developer Forums
2. Review App Store Connect status page
3. Contact Apple Developer Support (2 technical support incidents included annually)
4. Check Xcode console logs for StoreKit errors

**Common StoreKit Error Codes:**
- `0`: Success!
- `2`: Product not available (wait for propagation, check bundle ID)
- `3`: Client invalid (bundle ID mismatch)
- `5`: Cannot connect to iTunes Store (network issue)
- `6`: Payment cancelled by user
- `7`: Payment not allowed (restrictions enabled)

---

**Good luck with your launch! 🚀**

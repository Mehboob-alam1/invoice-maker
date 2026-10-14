# Remote Config

Fetch waits at most 2 seconds on startup. Release fetches at most every 12 hours. Debug fetches every launch. A realtime update applies on the next screen. `ad_config_version` is an Analytics user property.

Country, version, and language conditions are set in the Firebase console. The app reads the value that matches the device. It does not hard-code conditions.

| Key | Type | Default | Meaning |
|---|---|---|---|
| ads_enabled | bool | true | Master switch. False hides every ad, including one already loaded. |
| ad_config_version | string | 1 | Analytics user property for this config. |
| ad_native_google | bool | false | Native ad on Google sign-in. |
| ad_native_business_name | bool | false | Native ad on business name. |
| ad_interstitial_nav_screens | bool | false | Interstitial when opening Clients, Items, or Language. |
| interstitial_min_interval_sec | number | 90 | Minimum gap between interstitials. |
| interstitial_max_per_session | number | 4 | Interstitial cap for one process. |
| interstitial_max_per_day | number | 12 | Interstitial cap per day. |
| app_open_min_interval_min | number | 240 | Minimum gap between app-open ads. |
| app_open_max_per_day | number | 4 | App-open cap per day. |
| app_open_min_background_sec | number | 30 | Resume app-open ads need this much time in the background. |
| ads_grace_until_first_invoice | bool | true | No interstitial or app-open ad before the first saved invoice. |
| paywall_after_settings_mode | string | once_per_day | Stored for the next phase. Not applied yet. |

Every `AdPlacement.remoteKey` is also a bool. New ones include `ad_interstitial_save_invoice`, `ad_interstitial_preview_back`, `ad_rewarded_ai_credit`, `ad_rewarded_extra_invoice`, and `ad_native_home_list`. Their switches exist and are used: a new invoice save, leaving preview, an extra AI credit, an extra invoice, and the home-list native ad. Leaving Settings opens the paywall at most once a day.

Other stored defaults (not applied in the UI yet): `paywall_variant=A`, `plans_enabled=weekly,monthly,yearly`, `paywall_default_plan=yearly`, `free_invoices_per_day=3`, `free_ai_credits_per_month=3`, referral reward numbers, `watermark_footer_free=true`, `review_prompt_enabled=true`.

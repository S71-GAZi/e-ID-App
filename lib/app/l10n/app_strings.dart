import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Localization-ready string table.
///
/// All UI text goes through `AppStrings.of(context)` so we can later swap in
/// generated `intl` ARB files without touching call sites. Supported
/// languages: English and Bangla (বাংলা). The active locale is controlled by
/// [localeProvider] (persisted locally) — users switch it in Settings.
class AppStrings {
  const AppStrings({
    required this.appName,
    required this.tagline,
    // Auth
    required this.signIn,
    required this.signUp,
    required this.email,
    required this.password,
    required this.fullName,
    required this.forgotPassword,
    required this.resetLinkSent,
    required this.continueWithGoogle,
    required this.continueWithApple,
    required this.orContinueWith,
    // Tabs / nav
    required this.tabMyCards,
    required this.tabWallet,
    required this.tabShare,
    // Cards
    required this.newCard,
    required this.editCard,
    required this.cardLabel,
    required this.jobTitle,
    required this.company,
    required this.phone,
    required this.emailAddress,
    required this.website,
    required this.address,
    required this.bio,
    required this.socialLinks,
    required this.visibility,
    required this.visibleToOthers,
    required this.hidden,
    required this.photo,
    required this.takePhoto,
    required this.chooseFromGallery,
    required this.theme,
    required this.save,
    required this.cancel,
    required this.delete,
    required this.saved,
    required this.work,
    required this.personal,
    // QR / share
    required this.showQr,
    required this.scanQr,
    required this.copyLink,
    required this.linkCopied,
    required this.onlineMode,
    required this.offlineMode,
    required this.qrBrightnessHint,
    // Wallet
    required this.walletEmpty,
    required this.searchCards,
    required this.saveToWallet,
    required this.addToContacts,
    required this.notes,
    required this.tags,
    // Errors
    required this.genericError,
    required this.networkError,
    required this.validationRequired,
    required this.validationUrl,
    required this.passwordResetSubject,
    // Settings / preferences
    required this.settings,
    required this.language,
    required this.appearance,
    required this.lightMode,
    required this.darkMode,
    required this.systemMode,
    required this.accentColor,
    required this.continueOffline,
    required this.offlineBanner,
  });

  final String appName;
  final String tagline;
  final String signIn;
  final String signUp;
  final String email;
  final String password;
  final String fullName;
  final String forgotPassword;
  final String resetLinkSent;
  final String continueWithGoogle;
  final String continueWithApple;
  final String orContinueWith;
  final String tabMyCards;
  final String tabWallet;
  final String tabShare;
  final String newCard;
  final String editCard;
  final String cardLabel;
  final String jobTitle;
  final String company;
  final String phone;
  final String emailAddress;
  final String website;
  final String address;
  final String bio;
  final String socialLinks;
  final String visibility;
  final String visibleToOthers;
  final String hidden;
  final String photo;
  final String takePhoto;
  final String chooseFromGallery;
  final String theme;
  final String save;
  final String cancel;
  final String delete;
  final String saved;
  final String work;
  final String personal;
  final String showQr;
  final String scanQr;
  final String copyLink;
  final String linkCopied;
  final String onlineMode;
  final String offlineMode;
  final String qrBrightnessHint;
  final String walletEmpty;
  final String searchCards;
  final String saveToWallet;
  final String addToContacts;
  final String notes;
  final String tags;
  final String genericError;
  final String networkError;
  final String validationRequired;
  final String validationUrl;
  final String passwordResetSubject;
  final String settings;
  final String language;
  final String appearance;
  final String lightMode;
  final String darkMode;
  final String systemMode;
  final String accentColor;
  final String continueOffline;
  final String offlineBanner;

  static const AppStrings en = AppStrings(
    appName: 'E-ID',
    tagline: 'Your business card, one tap away',
    signIn: 'Sign in',
    signUp: 'Create account',
    email: 'Email',
    password: 'Password',
    fullName: 'Full name',
    forgotPassword: 'Forgot password?',
    resetLinkSent: 'Password reset link sent to your email',
    continueWithGoogle: 'Continue with Google',
    continueWithApple: 'Continue with Apple',
    orContinueWith: 'or continue with',
    tabMyCards: 'My cards',
    tabWallet: 'Wallet',
    tabShare: 'Share',
    newCard: 'New card',
    editCard: 'Edit card',
    cardLabel: 'Card label (e.g. Work)',
    jobTitle: 'Job title',
    company: 'Company',
    phone: 'Phone',
    emailAddress: 'Email address',
    website: 'Website',
    address: 'Address',
    bio: 'Short bio',
    socialLinks: 'Social links',
    visibility: 'Visibility',
    visibleToOthers: 'Visible to others',
    hidden: 'Hidden',
    photo: 'Photo',
    takePhoto: 'Take photo',
    chooseFromGallery: 'Choose from gallery',
    theme: 'Theme',
    save: 'Save',
    cancel: 'Cancel',
    delete: 'Delete',
    saved: 'Saved',
    work: 'Work',
    personal: 'Personal',
    showQr: 'Show QR',
    scanQr: 'Scan QR',
    copyLink: 'Copy link',
    linkCopied: 'Link copied',
    onlineMode: 'Online',
    offlineMode: 'Offline',
    qrBrightnessHint: 'Turn up your screen brightness for easier scanning',
    walletEmpty: 'No cards yet. Scan a QR code to add one.',
    searchCards: 'Search cards',
    saveToWallet: 'Save to my wallet',
    addToContacts: 'Add to contacts',
    notes: 'Notes',
    tags: 'Tags',
    genericError: 'Something went wrong. Please try again.',
    networkError: 'Network error. Check your connection.',
    validationRequired: 'This field is required',
    validationUrl: 'Enter a valid URL (https://…)',
    passwordResetSubject: 'Reset your E-ID password',
    settings: 'Settings',
    language: 'Language',
    appearance: 'Appearance',
    lightMode: 'Light',
    darkMode: 'Dark',
    systemMode: 'System',
    accentColor: 'Accent color',
    continueOffline: 'Continue offline',
    offlineBanner: 'You are using E-ID offline. Your data is saved on this '
        'device and will sync when you sign in.',
  );

  /// Bangla (বাংলা).
  static const AppStrings bn = AppStrings(
    appName: 'ই-আইডি',
    tagline: 'আপনার ভিজিটিং কার্ড, এক ট্যাপে',
    signIn: 'সাইন ইন করুন',
    signUp: 'অ্যাকাউন্ট তৈরি করুন',
    email: 'ইমেইল',
    password: 'পাসওয়ার্ড',
    fullName: 'পুরো নাম',
    forgotPassword: 'পাসওয়ার্ড ভুলে গেছেন?',
    resetLinkSent: 'আপনার ইমেইলে পাসওয়ার্ড রিসেট লিংক পাঠানো হয়েছে',
    continueWithGoogle: 'Google দিয়ে চালিয়ে যান',
    continueWithApple: 'Apple দিয়ে চালিয়ে যান',
    orContinueWith: 'অথবা এর মাধ্যমে চালিয়ে যান',
    tabMyCards: 'আমার কার্ড',
    tabWallet: 'ওয়ালেট',
    tabShare: 'শেয়ার',
    newCard: 'নতুন কার্ড',
    editCard: 'কার্ড সম্পাদনা',
    cardLabel: 'কার্ডের লেবেল (যেমন কাজ)',
    jobTitle: 'পদবি',
    company: 'প্রতিষ্ঠান',
    phone: 'ফোন',
    emailAddress: 'ইমেইল ঠিকানা',
    website: 'ওয়েবসাইট',
    address: 'ঠিকানা',
    bio: 'সংক্ষিপ্ত পরিচিতি',
    socialLinks: 'সোশ্যাল লিংক',
    visibility: 'দৃশ্যমানতা',
    visibleToOthers: 'অন্যদের জন্য দৃশ্যমান',
    hidden: 'গোপন',
    photo: 'ছবি',
    takePhoto: 'ছবি তুলুন',
    chooseFromGallery: 'গ্যালারি থেকে বেছে নিন',
    theme: 'থিম',
    save: 'সংরক্ষণ',
    cancel: 'বাতিল',
    delete: 'মুছুন',
    saved: 'সংরক্ষিত',
    work: 'কাজ',
    personal: 'ব্যক্তিগত',
    showQr: 'QR দেখান',
    scanQr: 'QR স্ক্যান',
    copyLink: 'লিংক কপি করুন',
    linkCopied: 'লিংক কপি হয়েছে',
    onlineMode: 'অনলাইন',
    offlineMode: 'অফলাইন',
    qrBrightnessHint: 'সহজে স্ক্যানের জন্য স্ক্রিনের উজ্জ্বলতা বাড়ান',
    walletEmpty: 'এখনও কোনো কার্ড নেই। একটি QR কোড স্ক্যান করে যোগ করুন।',
    searchCards: 'কার্ড খুঁজুন',
    saveToWallet: 'আমার ওয়ালেটে সংরক্ষণ করুন',
    addToContacts: 'কনট্যাক্টে যোগ করুন',
    notes: 'নোট',
    tags: 'ট্যাগ',
    genericError: 'কিছু একটা সমস্যা হয়েছে। আবার চেষ্টা করুন।',
    networkError: 'নেটওয়ার্ক সমস্যা। আপনার সংযোগ পরীক্ষা করুন।',
    validationRequired: 'এই ঘরটি পূরণ করা আবশ্যক',
    validationUrl: 'একটি বৈধ URL লিখুন (https://…)',
    passwordResetSubject: 'আপনার ই-আইডি পাসওয়ার্ড রিসেট করুন',
    settings: 'সেটিংস',
    language: 'ভাষা',
    appearance: 'চেহারা',
    lightMode: 'লাইট',
    darkMode: 'ডার্ক',
    systemMode: 'সিস্টেম',
    accentColor: 'অ্যাকসেন্ট রঙ',
    continueOffline: 'অফলাইনে চালিয়ে যান',
    offlineBanner: 'আপনি ই-আইডি অফলাইনে ব্যবহার করছেন। আপনার তথ্য এই ডিভাইসে '
        'সংরক্ষিত থাকবে এবং সাইন ইন করার পর সিঙ্ক হবে।',
  );

  static const Map<Locale, AppStrings> _all = {
    Locale('en'): en,
    Locale('bn'): bn,
  };

  /// Human-readable names for the language picker (always shown in their own
  /// script, so they must NOT go through the string table).
  static const Map<String, String> languageNames = {
    'en': 'English',
    'bn': 'বাংলা',
  };

  static AppStrings of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return _all[locale] ?? _all[Locale(locale.languageCode)] ?? en;
  }

  static Iterable<Locale> get supportedLocales => _all.keys;

  /// Delegate used by MaterialApp.localizationsDelegates.
  static const LocalizationsDelegate<AppStrings> delegate =
      _AppStringsDelegate();
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppStrings._all.containsKey(Locale(locale.languageCode));

  @override
  Future<AppStrings> load(Locale locale) async =>
      AppStrings._all[Locale(locale.languageCode)] ?? AppStrings.en;

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppStrings> old) => false;
}

// ---------------------------------------------------------------------------
// User preferences (language + theme mode + accent color), persisted locally
// via SharedPreferences so offline users keep their choices across launches.
// The instance is preloaded once in main() before the ProviderScope runs,
// which lets every notifier read/write synchronously through [prefs].
// ---------------------------------------------------------------------------

/// Shared access to the preloaded SharedPreferences instance.
abstract final class AppPrefs {
  static SharedPreferences? prefs;

  /// Call once during app startup, before runApp/ProviderScope.
  static Future<void> preload() async {
    prefs = await SharedPreferences.getInstance();
  }
}

/// Which app language is active. `null` means "follow the system language".
final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<Locale?> {
  static const _keyLanguage = 'pref_language_code';

  @override
  Locale? build() {
    final code = AppPrefs.prefs?.getString(_keyLanguage);
    if (code == null || code.isEmpty) return null;
    return Locale(code);
  }

  /// Pass 'system' to follow the device language again.
  Future<void> setLanguage(String languageCode) async {
    if (languageCode == 'system') {
      state = null;
      await AppPrefs.prefs?.remove(_keyLanguage);
    } else {
      state = Locale(languageCode);
      await AppPrefs.prefs?.setString(_keyLanguage, languageCode);
    }
  }
}

/// Light / dark / system theme preference.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'pref_theme_mode';

  @override
  ThemeMode build() {
    final raw = AppPrefs.prefs?.getString(_key);
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await AppPrefs.prefs?.setString(_key, mode.name);
  }
}

/// Selected accent color (index into AppColors.cardAccents).
final accentIndexProvider = NotifierProvider<AccentNotifier, int>(
  AccentNotifier.new,
);

class AccentNotifier extends Notifier<int> {
  static const _key = 'pref_accent_index';

  @override
  int build() => AppPrefs.prefs?.getInt(_key) ?? 0;

  Future<void> set(int index) async {
    state = index;
    await AppPrefs.prefs?.setInt(_key, index);
  }
}

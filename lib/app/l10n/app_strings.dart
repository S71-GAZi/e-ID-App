import 'package:flutter/material.dart';

/// Localization-ready string table.
///
/// All UI text goes through `AppStrings.of(context)` so we can later swap in
/// generated `intl` ARB files without touching call sites. Default language is
/// English; add new locales by extending the map below (or migrating to
/// flutter gen-l10n with .arb files when translations are ready).
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
  );

  /// Example second locale — fill in real translations when localization is
  /// scheduled. Falls back to [en] for any missing strings.
  static const AppStrings es = AppStrings(
    appName: 'E-ID',
    tagline: 'Tu tarjeta de presentación, a un toque',
    signIn: 'Iniciar sesión',
    signUp: 'Crear cuenta',
    email: 'Correo',
    password: 'Contraseña',
    fullName: 'Nombre completo',
    forgotPassword: '¿Olvidaste tu contraseña?',
    resetLinkSent: 'Enviamos un enlace para restablecer la contraseña',
    continueWithGoogle: 'Continuar con Google',
    continueWithApple: 'Continuar con Apple',
    orContinueWith: 'o continuar con',
    tabMyCards: 'Mis tarjetas',
    tabWallet: 'Cartera',
    tabShare: 'Compartir',
    newCard: 'Nueva tarjeta',
    editCard: 'Editar tarjeta',
    cardLabel: 'Etiqueta (ej. Trabajo)',
    jobTitle: 'Puesto',
    company: 'Empresa',
    phone: 'Teléfono',
    emailAddress: 'Correo electrónico',
    website: 'Sitio web',
    address: 'Dirección',
    bio: 'Biografía breve',
    socialLinks: 'Redes sociales',
    visibility: 'Visibilidad',
    visibleToOthers: 'Visible para otros',
    hidden: 'Oculto',
    photo: 'Foto',
    takePhoto: 'Tomar foto',
    chooseFromGallery: 'Elegir de la galería',
    theme: 'Tema',
    save: 'Guardar',
    cancel: 'Cancelar',
    delete: 'Eliminar',
    saved: 'Guardado',
    work: 'Trabajo',
    personal: 'Personal',
    showQr: 'Mostrar QR',
    scanQr: 'Escanear QR',
    copyLink: 'Copiar enlace',
    linkCopied: 'Enlace copiado',
    onlineMode: 'En línea',
    offlineMode: 'Sin conexión',
    qrBrightnessHint: 'Sube el brillo de la pantalla para facilitar el escaneo',
    walletEmpty: 'Aún no hay tarjetas. Escanea un código QR.',
    searchCards: 'Buscar tarjetas',
    saveToWallet: 'Guardar en mi cartera',
    addToContacts: 'Añadir a contactos',
    notes: 'Notas',
    tags: 'Etiquetas',
    genericError: 'Algo salió mal. Inténtalo de nuevo.',
    networkError: 'Error de red. Revisa tu conexión.',
    validationRequired: 'Este campo es obligatorio',
    validationUrl: 'Ingresa una URL válida (https://…)',
    passwordResetSubject: 'Restablece tu contraseña de E-ID',
  );

  static const Map<Locale, AppStrings> _all = {
    Locale('en'): en,
    Locale('es'): es,
  };

  static AppStrings of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return _all[locale] ?? _all[locale.languageCode]! ?? en;
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

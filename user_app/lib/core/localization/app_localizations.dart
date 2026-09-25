import 'package:flutter/material.dart';

/// Mfumo wa lugha — Kiswahili (default) + English.
/// Matumizi: AppLocalizations.of(context).t('key')
class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('sw'), // Kiswahili (default)
    Locale('en'), // English
  ];

  static final Map<String, Map<String, String>> _values = {
    'sw': {
      // ===== GENERAL =====
      'app_name': 'Smart Garage',
      'ok': 'Sawa',
      'cancel': 'Ghairi',
      'save': 'Hifadhi',
      'delete': 'Futa',
      'edit': 'Badilisha',
      'close': 'Funga',
      'yes': 'Ndiyo',
      'no': 'Hapana',
      'retry': 'Jaribu Tena',
      'loading': 'Inapakia...',
      'error': 'Kuna tatizo',
      'success': 'Imefanikiwa',
      'search': 'Tafuta',
      'back': 'Rudi',

      // ===== AUTH =====
      'login': 'Ingia',
      'register': 'Jisajili',
      'logout': 'Toka',
      'email': 'Barua Pepe',
      'password': 'Neno la Siri',
      'forgot_password': 'Umesahau neno la siri?',
      'no_account': 'Hauna akaunti? Jisajili',
      'have_account': 'Una akaunti? Ingia',
      'welcome_back': 'Karibu Tena',

      // ===== HOME / NAV =====
      'home': 'Nyumbani',
      'services': 'Huduma',
      'mechanics': 'Mafundi',
      'spare_parts': 'Vipuri',
      'profile': 'Wasifu',
      'wallet': 'Pochi',
      'bookings': 'Oda Zangu',
      'chat': 'Mazungumzo',
      'notifications': 'Taarifa',
      'settings': 'Mipangilio',

      // ===== AI DIAGNOSIS =====
      'ai_diagnosis': 'Uchunguzi wa AI',
      'ai_greeting': 'Habari',
      'ai_subtitle': 'Ninaweza kukusaidia kuchunguza tatizo la gari lako',
      'ai_ask_placeholder': 'Andika tatizo la gari lako...',
      'ai_send': 'Tuma',
      'ai_upload_photo': 'Tuma picha',
      'ai_thinking': 'AI inachambua...',
      'ai_reset': 'Anza Upya',
      'ai_reset_confirm': 'Ujumbe wote utafutwa. Una uhakika?',
      'ai_find_mechanic_cta': 'Hujaridhika? Mwone mechanic wetu.',
      'ai_find_mechanic': 'Tafuta Fundi',
      'ai_suggestions': '💡 Jaribu kuuliza:',

      // ===== MECHANIC =====
      'find_mechanic': 'Tafuta Fundi',
      'book_mechanic': 'Weka Fundi',
      'mechanic_nearby': 'Mafundi Karibu',
      'mechanic_rating': 'Kiwango',
      'mechanic_experience': 'Uzoefu',
      'mechanic_location': 'Mahali',
      'mechanic_contact': 'Wasiliana',
      'request_approval': 'Omba Ruhusa',
      'waiting_approval': 'Inasubiri mechanic akubali...',
      'approved_book': 'Sasa unaweza ku-book!',

      // ===== LANGUAGE =====
      'language': 'Lugha',
      'language_swahili': 'Kiswahili',
      'language_english': 'Kiingereza',
      'language_select': 'Chagua Lugha',

      // ===== SESSION =====
      'session_expired': 'Muda wako umeisha. Tafadhali ingia tena.',
      'logout_confirm': 'Una uhakika kutoka?',
    },
    'en': {
      // ===== GENERAL =====
      'app_name': 'Smart Garage',
      'ok': 'OK',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'close': 'Close',
      'yes': 'Yes',
      'no': 'No',
      'retry': 'Retry',
      'loading': 'Loading...',
      'error': 'Something went wrong',
      'success': 'Success',
      'search': 'Search',
      'back': 'Back',

      // ===== AUTH =====
      'login': 'Login',
      'register': 'Register',
      'logout': 'Logout',
      'email': 'Email',
      'password': 'Password',
      'forgot_password': 'Forgot password?',
      'no_account': "Don't have an account? Register",
      'have_account': 'Have an account? Login',
      'welcome_back': 'Welcome Back',

      // ===== HOME / NAV =====
      'home': 'Home',
      'services': 'Services',
      'mechanics': 'Mechanics',
      'spare_parts': 'Spare Parts',
      'profile': 'Profile',
      'wallet': 'Wallet',
      'bookings': 'My Bookings',
      'chat': 'Chat',
      'notifications': 'Notifications',
      'settings': 'Settings',

      // ===== AI DIAGNOSIS =====
      'ai_diagnosis': 'AI Diagnosis',
      'ai_greeting': 'Hello',
      'ai_subtitle': "I can help you diagnose your car's problem",
      'ai_ask_placeholder': "Describe your car's problem...",
      'ai_send': 'Send',
      'ai_upload_photo': 'Send photo',
      'ai_thinking': 'AI is analyzing...',
      'ai_reset': 'Start Over',
      'ai_reset_confirm': 'All messages will be deleted. Are you sure?',
      'ai_find_mechanic_cta': "Not satisfied? Find our mechanic.",
      'ai_find_mechanic': 'Find Mechanic',
      'ai_suggestions': '💡 Try asking:',

      // ===== MECHANIC =====
      'find_mechanic': 'Find Mechanic',
      'book_mechanic': 'Book Mechanic',
      'mechanic_nearby': 'Nearby Mechanics',
      'mechanic_rating': 'Rating',
      'mechanic_experience': 'Experience',
      'mechanic_location': 'Location',
      'mechanic_contact': 'Contact',
      'request_approval': 'Request Approval',
      'waiting_approval': 'Waiting for mechanic approval...',
      'approved_book': 'You can now book!',

      // ===== LANGUAGE =====
      'language': 'Language',
      'language_swahili': 'Swahili',
      'language_english': 'English',
      'language_select': 'Select Language',

      // ===== SESSION =====
      'session_expired': 'Your session expired. Please login again.',
      'logout_confirm': 'Are you sure you want to logout?',
    },
  };

  /// Pata tafsiri kwa key.
  String t(String key) {
    return _values[locale.languageCode]?[key] ?? _values['sw']?[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['sw', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

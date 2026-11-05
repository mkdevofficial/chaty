import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ChatyStrings {
  final Map<String, String> _localizedValues;

  ChatyStrings(this._localizedValues);

  String get(String key) => _localizedValues[key] ?? key;

  // App & Common
  String get appName => get('app_name');
  String get ok => get('ok');
  String get cancel => get('cancel');
  String get save => get('save');
  String get retry => get('retry');
  String get error => get('error');
  String get success => get('success');
  String get loading => get('loading');
  String get search => get('search');
  String get delete => get('delete');
  String get edit => get('edit');
  String get confirm => get('confirm');
  String get close => get('close');

  // Auth
  String get login => get('login');
  String get register => get('register');
  String get phone => get('phone');
  String get username => get('username');
  String get displayName => get('display_name');
  String get password => get('password');
  String get bio => get('bio');
  String get welcomeBack => get('welcome_back');
  String get loginSubtitle => get('login_subtitle');
  String get createAccount => get('create_account');
  String get registerSubtitle => get('register_subtitle');
  String get noAccount => get('no_account');
  String get haveAccount => get('have_account');
  String get logout => get('logout');
  String get logoutConfirm => get('logout_confirm');
  String get invalidPhone => get('invalid_phone');
  String get invalidUsername => get('invalid_username');
  String get invalidPassword => get('invalid_password');
  String get invalidDisplayName => get('invalid_display_name');

  // Chats & Messages
  String get chats => get('chats');
  String get noChatsYet => get('no_chats_yet');
  String get startConversation => get('start_conversation');
  String get typing => get('typing');
  String get online => get('online');
  String get offline => get('offline');
  String get lastSeen => get('last_seen');
  String get typeMessage => get('type_message');
  String get slideToCancel => get('slide_to_cancel');
  String get recordingVoice => get('recording_voice');
  String get today => get('today');
  String get yesterday => get('yesterday');
  String get photo => get('photo');
  String get voiceNote => get('voice_note');
  String get file => get('file');
  String get sticker => get('sticker');
  String get failedToSendMessage => get('failed_to_send_message');
  String get tapToRetry => get('tap_to_retry');
  String get camera => get('camera');
  String get gallery => get('gallery');
  String get document => get('document');
  String get download => get('download');
  String get downloading => get('downloading');
  String get downloaded => get('downloaded');
  String get open => get('open');

  // Stories
  String get stories => get('stories');
  String get myStory => get('my_story');
  String get addStory => get('add_story');
  String get createStory => get('create_story');
  String get textStory => get('text_story');
  String get photoStory => get('photo_story');
  String get storyCaptionPlaceholder => get('story_caption_placeholder');
  String get storyTextPlaceholder => get('story_text_placeholder');
  String get viewers => get('viewers');
  String get noViewersYet => get('no_viewers_yet');
  String get deleteStoryConfirm => get('delete_story_confirm');
  String get shareStory => get('share_story');

  // Friends & Users
  String get searchUsers => get('search_users');
  String get searchPlaceholder => get('search_placeholder');
  String get noUsersFound => get('no_users_found');
  String get follow => get('follow');
  String get following => get('following');
  String get unfollow => get('unfollow');
  String get followers => get('followers');
  String get sendMessage => get('send_message');
  String get userNotFound => get('user_not_found');

  // Profile
  String get myProfile => get('my_profile');
  String get editProfile => get('edit_profile');
  String get changePhoto => get('change_photo');
  String get profileUpdated => get('profile_updated');

  // Settings
  String get settings => get('settings');
  String get appearance => get('appearance');
  String get theme => get('theme');
  String get themeSystem => get('theme_system');
  String get themeLight => get('theme_light');
  String get themeDark => get('theme_dark');
  String get accentColor => get('accent_color');
  String get chatWallpaper => get('chat_wallpaper');
  String get language => get('language');
  String get arabic => get('arabic');
  String get english => get('english');
  String get serverConfig => get('server_config');
  String get serverUrl => get('server_url');

  // Errors & Network
  String get serverUnreachable => get('server_unreachable');
  String get connectionTimeout => get('connection_timeout');
  String get sessionExpired => get('session_expired');
  String get unknownError => get('unknown_error');
  String get permissionDenied => get('permission_denied');
  String get permissionRequired => get('permission_required');

  // Stickers
  String get recent => get('recent');
  String get emojisPack => get('emojis_pack');
  String get catsPack => get('cats_pack');
  String get gesturesPack => get('gestures_pack');
  String get noRecentStickers => get('no_recent_stickers');
}

class AppLocalizations {
  final Locale locale;
  late final ChatyStrings strings;

  AppLocalizations(this.locale) {
    strings = ChatyStrings(
      locale.languageCode == 'en' ? _enValues : _arValues,
    );
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('ar'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const Map<String, String> _arValues = {
    'app_name': 'chaty',
    'ok': 'حسناً',
    'cancel': 'إلغاء',
    'save': 'حفظ',
    'retry': 'إعادة المحاولة',
    'error': 'خطأ',
    'success': 'تم بنجاح',
    'loading': 'جاري التحميل...',
    'search': 'بحث',
    'delete': 'حذف',
    'edit': 'تعديل',
    'confirm': 'تأكيد',
    'close': 'إغلاق',

    'login': 'تسجيل الدخول',
    'register': 'إنشاء حساب جديد',
    'phone': 'رقم الهاتف',
    'username': 'اسم المستخدم',
    'display_name': 'الاسم الظاهر',
    'password': 'كلمة المرور',
    'bio': 'نبذة تعريفية',
    'welcome_back': 'مرحباً بعودتك!',
    'login_subtitle': 'سجل الدخول للمتابعة مع أصدقائك',
    'create_account': 'حساب جديد',
    'register_subtitle': 'انضم إلى مجتمع chaty الآن',
    'no_account': 'ليس لديك حساب؟ أنشئ حساباً',
    'have_account': 'لديك حساب بالفعل؟ سجل دخولك',
    'logout': 'تسجيل الخروج',
    'logout_confirm': 'هل أنت متأكد من رغبتك في تسجيل الخروج؟',
    'invalid_phone': 'يرجى إدخال رقم هاتف صحيح',
    'invalid_username': 'اسم المستخدم يجب أن يتكون من 3 أحرف على الأقل',
    'invalid_password': 'كلمة المرور يجب ألا تقل عن 6 خانات',
    'invalid_display_name': 'يرجى إدخال اسمك الظاهر',

    'chats': 'المحادثات',
    'no_chats_yet': 'لا توجد محادثات حتى الآن',
    'start_conversation': 'ابدأ محادثة جديدة الآن',
    'typing': 'يكتب الآن...',
    'online': 'متصل الآن',
    'offline': 'غير متصل',
    'last_seen': 'آخر ظهور',
    'type_message': 'اكتب رسالتك هنا...',
    'slide_to_cancel': 'اسحب للإلغاء',
    'recording_voice': 'جاري التسجيل الصوتى...',
    'today': 'اليوم',
    'yesterday': 'أمس',
    'photo': 'صورة',
    'voice_note': 'رسالة صوتية',
    'file': 'ملف',
    'sticker': 'ملصق',
    'failed_to_send_message': 'فشل إرسال الرسالة',
    'tap_to_retry': 'اضغط للمحاولة مجدداً',
    'camera': 'الكاميرا',
    'gallery': 'معرض الصور',
    'document': 'ملف / مستند',
    'download': 'تحميل',
    'downloading': 'جاري التحميل...',
    'downloaded': 'تم التحميل بنجاح',
    'open': 'فتح',

    'stories': 'القصص',
    'my_story': 'قصتي',
    'add_story': 'إضافة قصة',
    'create_story': 'إنشاء قصة جديدة',
    'text_story': 'قصة نصية',
    'photo_story': 'قصة مصورة',
    'story_caption_placeholder': 'أضف تعليقاً على الصورة...',
    'story_text_placeholder': 'ما الذي يدور في ذهنك؟',
    'viewers': 'المشاهدات',
    'no_viewers_yet': 'لا توجد مشاهدات حتى الآن',
    'delete_story_confirm': 'هل تريد بالتأكيد حذف هذه القصة؟',
    'share_story': 'نشر القصة',

    'search_users': 'البحث عن مستخدمين',
    'search_placeholder': 'ابحث بالهاتف أو اسم المستخدم @...',
    'no_users_found': 'لم يتم العثور على أي مستخدمين',
    'follow': 'متابعة',
    'following': 'متابع',
    'unfollow': 'إلغاء المتابعة',
    'followers': 'المتابعون',
    'send_message': 'إرسال رسالة',
    'user_not_found': 'المستخدم غير موجود',

    'my_profile': 'ملفي الشخصي',
    'edit_profile': 'تعديل الملف الشخصي',
    'change_photo': 'تغيير الصورة',
    'profile_updated': 'تم تحديث الملف الشخصي بنجاح',

    'settings': 'الإعدادات',
    'appearance': 'المظهر والألوان',
    'theme': 'السمة',
    'theme_system': 'تلقائي حسب النظام',
    'theme_light': 'الوضع المضيء',
    'theme_dark': 'الوضع الداكن',
    'accent_color': 'اللون المميز',
    'chat_wallpaper': 'خلفية المحادثات',
    'language': 'اللغة',
    'arabic': 'العربية (RTL)',
    'english': 'English',
    'server_config': 'إعدادات السيرفر',
    'server_url': 'عنوان السيرفر',

    'server_unreachable': 'تعذر الاتصال بالسيرفر. يرجى التحقق من اتصالك بالإنترنت.',
    'connection_timeout': 'انتهت مهلة الاتصال بالخادم. حاول ثانية.',
    'session_expired': 'انتهت جلستك، يرجى تسجيل الدخول مجدداً.',
    'unknownError': 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى.',
    'permissionDenied': 'تم رفض الإذن المطلوب. يرجى تفعيله من الإعدادات.',
    'permissionRequired': 'هذه الميزة تتطلب صلاحيات وصول للعمل.',

    'recent': 'الأخيرة',
    'emojis_pack': 'رموز تعبيرية',
    'cats_pack': 'قطط ظريفة',
    'gestures_pack': 'إيماءات اليد',
    'no_recent_stickers': 'لا توجد ملصقات مستخدمة مؤخراً',
  };

  static const Map<String, String> _enValues = {
    'app_name': 'chaty',
    'ok': 'OK',
    'cancel': 'Cancel',
    'save': 'Save',
    'retry': 'Retry',
    'error': 'Error',
    'success': 'Success',
    'loading': 'Loading...',
    'search': 'Search',
    'delete': 'Delete',
    'edit': 'Edit',
    'confirm': 'Confirm',
    'close': 'Close',

    'login': 'Login',
    'register': 'Register',
    'phone': 'Phone Number',
    'username': 'Username',
    'display_name': 'Display Name',
    'password': 'Password',
    'bio': 'Bio',
    'welcome_back': 'Welcome Back!',
    'login_subtitle': 'Sign in to continue chatting with friends',
    'create_account': 'Create Account',
    'register_subtitle': 'Join the chaty community today',
    'no_account': 'Don\'t have an account? Sign up',
    'have_account': 'Already have an account? Log in',
    'logout': 'Log Out',
    'logout_confirm': 'Are you sure you want to log out?',
    'invalid_phone': 'Please enter a valid phone number',
    'invalid_username': 'Username must be at least 3 characters',
    'invalid_password': 'Password must be at least 6 characters',
    'invalid_display_name': 'Please enter a display name',

    'chats': 'Chats',
    'no_chats_yet': 'No conversations yet',
    'start_conversation': 'Start a new conversation now',
    'typing': 'Typing...',
    'online': 'Online',
    'offline': 'Offline',
    'last_seen': 'Last seen',
    'type_message': 'Type a message...',
    'slide_to_cancel': 'Slide to cancel',
    'recording_voice': 'Recording voice note...',
    'today': 'Today',
    'yesterday': 'Yesterday',
    'photo': 'Photo',
    'voice_note': 'Voice note',
    'file': 'File',
    'sticker': 'Sticker',
    'failed_to_send_message': 'Failed to send message',
    'tap_to_retry': 'Tap to retry',
    'camera': 'Camera',
    'gallery': 'Gallery',
    'document': 'Document',
    'download': 'Download',
    'downloading': 'Downloading...',
    'downloaded': 'Downloaded successfully',
    'open': 'Open',

    'stories': 'Stories',
    'my_story': 'My Story',
    'add_story': 'Add Story',
    'create_story': 'Create Story',
    'text_story': 'Text Story',
    'photo_story': 'Photo Story',
    'story_caption_placeholder': 'Add a caption...',
    'story_text_placeholder': 'What\'s on your mind?',
    'viewers': 'Viewers',
    'no_viewers_yet': 'No viewers yet',
    'delete_story_confirm': 'Are you sure you want to delete this story?',
    'share_story': 'Share Story',

    'search_users': 'Search Users',
    'search_placeholder': 'Search by phone or @username...',
    'no_users_found': 'No users found',
    'follow': 'Follow',
    'following': 'Following',
    'unfollow': 'Unfollow',
    'followers': 'Followers',
    'send_message': 'Send Message',
    'user_not_found': 'User not found',

    'my_profile': 'My Profile',
    'edit_profile': 'Edit Profile',
    'change_photo': 'Change Photo',
    'profile_updated': 'Profile updated successfully',

    'settings': 'Settings',
    'appearance': 'Appearance',
    'theme': 'Theme',
    'theme_system': 'System Default',
    'theme_light': 'Light Mode',
    'theme_dark': 'Dark Mode',
    'accent_color': 'Accent Color',
    'chat_wallpaper': 'Chat Wallpaper',
    'language': 'Language',
    'arabic': 'العربية (RTL)',
    'english': 'English',
    'server_config': 'Server Configuration',
    'server_url': 'Server URL',

    'server_unreachable': 'Could not connect to the server. Please check your internet.',
    'connection_timeout': 'Connection timed out. Please try again.',
    'session_expired': 'Your session expired. Please log in again.',
    'unknown_error': 'An unexpected error occurred. Please try again.',
    'permission_denied': 'Required permission was denied.',
    'permission_required': 'This feature requires access permissions.',

    'recent': 'Recent',
    'emojis_pack': 'Emojis',
    'cats_pack': 'Cute Cats',
    'gestures_pack': 'Gestures',
    'no_recent_stickers': 'No recent stickers',
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

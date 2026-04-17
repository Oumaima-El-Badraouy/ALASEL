/// Textes interface — arabe (RTL).
class S {
  S._();

  static const String appName = 'الأصل';

  // Accueil (home)
  static const String homeDecorLine = 'مرحبا — الأصل';
  static const String homeMainTitle = 'الأصل';
  static const String homeIntroSubtitle = 'زخرفة زليج وألوان المغرب: ثقة وحرفة أصيلة.';
  static const String homeCardExploreTitle = 'استكشف الحرفيين';
  static const String homeCardExploreSubtitle = 'المهنة، المدينة، التوفر، التقييمات';
  static const String homeCardRequestTitle = 'طلب خدمة';
  static const String homeCardRequestSubtitle = 'تقدير الميزانية والمطابقة';
  static const String homeCardArtisanTitle = 'فضاء الحرفي';
  static const String homeCardArtisanSubtitle = 'الملف، معرض قبل/بعد';
  static const String mediouna = 'مديونة';
  static const String welcomeMediouna = 'حرفيون موثوقون — مديونة أولاً';

  // Shell / nav
  static const String messages = 'الرسائل';
  static const String reportProblem = 'إبلاغ عن مشكلة';
  static const String reportHint = 'صف المشكلة وسنعالجها بأسرع ما يمكن.';
  static const String reportCategoryOptional = 'التصنيف (اختياري)';
  static const String reportDetails = 'التفاصيل';
  static const String send = 'إرسال';
  static const String cancel = 'إلغاء';
  static const String reportSent = 'تم إرسال البلاغ. شكراً.';

  // Client nav
  static const String navHome = 'الرئيسية';
  static const String navFavorites = 'المفضلة';
  static const String navProfile = 'الملف';

  // Artisan nav
  static const String navDemands = 'الطلبات';
  static const String navDiscover = 'استكشاف';
  static const String navMyPosts = 'منشوراتي';

  // Feed
  static const String searchHint = 'بحث في المنشورات…';
  static const String sortRecent = 'الأحدث';
  static const String sortPopular = 'الأكثر شعبية';
  static const String filterAll = 'الكل';
  static const String noPosts = 'لا توجد منشورات حالياً.';

  /// مفاتيح API للفئات — عرض عربي.
  static String categoryLabel(String key) {
    switch (key) {
      case '':
        return filterAll;
      case 'plumbing':
        return 'سباكة';
      case 'painting':
        return 'دهان';
      case 'carpentry':
        return 'نجارة';
      case 'electricity':
        return 'كهرباء';
      case 'tiling':
        return 'بلاط';
      case 'hvac':
        return 'تكييف';
      default:
        return key;
    }
  }

  // Notifications
  static const String newInboxNotification = 'لديك رسالة جديدة';
  static const String notifNewDemand = 'طلب جديد من زبون في المنطقة';
  static const String notifNewService = 'منشور خدمة جديد';
  static const String notifNewComment = 'تعليق جديد على منشورك';
  static const String welcomeSnack = 'مرحباً بك في الأصل — مديونة';

  // Splash
  static const String arabicSubtitle = 'موثوقون في مديونة';

  // Auth
  static const String loginTitle = 'تسجيل الدخول';
  static const String welcomeLogin = 'مرحباً';
  static const String loginSubtitle = 'أدخل بياناتك للوصول إلى حسابك';
  static const String emailLabel = 'البريد الإلكتروني';
  static const String passwordLabel = 'كلمة المرور';
  static const String loginButton = 'دخول';
  static const String registerClient = 'إنشاء حساب زبون';
  static const String registerArtisan = 'إنشاء حساب حرفي';
  static const String errApiUnreachable =
      'تعذّر الاتصال بالخادم (منفذ 4000). شغّل الAPI على الجهاز. على هاتف حقيقي استخدم IP الحاسوب مع --dart-define=API_BASE=…';

  // Vérification e-mail + CIN
  static const String verifyEmailTitle = 'تأكيد البريد';
  static const String verifyEmailHint = 'اطلب رمزاً ثم أدخله هنا. في وضع التجربة يظهر الرمز في الرد.';
  static const String requestCodeBtn = 'إرسال الرمز';
  static const String confirmCodeBtn = 'تأكيد';
  static const String codeLabel = 'الرمز';
  static const String emailVerifiedOk = 'تم تأكيد البريد.';
  static const String cinRecto = 'صورة البطاقة (الوجه)';
  static const String cinVerso = 'صورة البطاقة (الظهر)';
  static const String cinSaved = 'تم حفظ صور البطاقة.';
  static const String accountVerification = 'التحقق من الحساب';

  // Inscription
  static const String registerArtisanTitle = 'تسجيل الحرفي';
  static const String registerClientTitle = 'تسجيل الزبون';
  static const String registerSubmit = 'إنشاء الحساب';
  static const String profilePhotoRecommended = 'صورة الملف (موصى بها)';
  static const String profilePhotoOptional = 'صورة الملف (اختياري — أو الأحرف الأولى)';
  static const String fieldFullNameRequired = 'الاسم الكامل (إلزامي)';
  static const String fieldDomainHint = 'المجال (سباكة، دهان…)';
  static const String fieldDescriptionArtisanRequired = 'وصف النشاط (إلزامي، 10 أحرف على الأقل)';
  static const String fieldPhoneRequired = 'الهاتف (إلزامي)';
  static const String fieldPasswordMin = 'كلمة المرور (6 أحرف على الأقل)';
  static const String mediounaConfirmLabel = 'أؤكد أنني ساكن في مديونة';
  static const String errMediounaRequired = 'يجب تأكيد الإقامة في مديونة.';
  static const String errDescMin10 = 'صف نشاطك (10 أحرف على الأقل).';
  static const String errCinBothRequired = 'أضف صورتي البطاقة الوطنية (الوجه والظهر).';
  static const String errClientRequiredFields = 'الاسم الأول والاسم والهاتف إلزاميون.';
  static const String cinRegisterSectionTitle = 'البطاقة الوطنية (إلزامي)';
  static const String imageTooLarge4mb = 'الصورة كبيرة جداً (الحد ~4 ميغابايت).';

  // Boîte de réception / liste
  static const String retry = 'إعادة المحاولة';
  static const String noMessagesYet = 'لا رسائل بعد.';
  static const String chatPeerFallback = 'محادثة';

  // Création de post
  static const String newServicePost = 'خدمة جديدة';
  static const String newRequestPost = 'طلب جديد';
  static const String createPostServiceHint =
      'أضف صورة أو فيديو (معاينة) وصف خدمتك.';
  static const String createPostRequestHint = 'صف احتياجك في مديونة.';
  static const String fieldDescription = 'الوصف';
  static const String fieldDomainCategory = 'المجال / التصنيف';
  static const String btnPhoto = 'صورة';
  static const String publish = 'نشر';

  // Découvrir / demandes / publications
  static const String otherArtisansTitle = 'حرفيون آخرون';
  static const String noOtherServices = 'لا توجد خدمات أخرى منشورة.';
  static const String clientDemandsScreenTitle = 'طلبات الزبائن — مديونة';
  static const String noDemandsYet = 'لا طلبات بعد.';
  static const String fabNew = 'جديد';
  static const String createFirstServicePost = 'أنشئ أول منشور خدمة';

  // Favoris
  static const String favoritesTitle = 'المفضلة';
  static const String favoritesEmpty = 'لا مفضلات بعد.\nأضف منشورات من الرئيسية.';

  // Commentaires
  static const String commentsTitle = 'التعليقات';
  static const String noCommentsYet = 'لا تعليقات. كن أول من يعلق.';
  static const String roleArtisanShort = 'حرفي';
  static const String roleClientShort = 'زبون';
  static const String messageButton = 'رسالة';
  static const String followButton = 'متابعة';
  static const String unfollowedSnack = 'تم إلغاء المتابعة';
  static const String followingSnack = 'أنت تتابع هذا الحرفي';
  static const String addCommentHint = 'أضف تعليقاً…';

  // Carte post
  static const String postTypeService = 'خدمة';
  static const String postTypeDemand = 'طلب';
  static const String fallbackArtisan = 'حرفي';
  static const String fallbackClient = 'زبون';
  static const String loginToComment = 'سجّل دخولك كزبون أو حرفي للتعليق.';
  static const String following = 'متابَع';

  // Explorer
  static const String exploreSubtitle = 'استكشف';
  static const String cityHint = 'المدينة (مثال: الدار البيضاء)';
  static const String availableOnly = 'المتاحون فقط';
  static const String noArtisansHint = 'لا حرفيين — شغّل الAPI وأنشئ حساباً تجريبياً.';
  static const String errorPrefix = 'خطأ: ';

  // Demande (request_screen)
  static const String fieldTitle = 'العنوان';
  static const String fieldCategory = 'التصنيف';
  static const String fieldCity = 'المدينة';
  static const String fieldSurfaceOptional = 'المساحة (م²) — اختياري';
  static const String fieldUrgency = 'الأولوية';
  static const String urgencyNormal = 'عادي';
  static const String urgencyUrgent = 'عاجل';
  static const String estimateBudget = 'تقدير الميزانية (درهم)';
  static const String publishRequest = 'نشر الطلب';
  static const String requestPublishedSnack = 'تم نشر الطلب';

  // Chat
  static const String callTooltip = 'اتصال';
  static const String allowMicSettings = 'اسمح بالميكروفون في الإعدادات.';
  static const String phoneNotSet = 'لا يوجد رقم لهذا الشخص.';
  static const String voiceMessage = 'رسالة صوتية';
  static const String audioPlaying = 'تشغيل…';
  static const String chatInputHint = 'اكتب رسالة…';
  static const String micRecord = 'تسجيل صوتي';
  static const String micStopSend = 'إيقاف وإرسال';
  static const String audioErrorPrefix = 'صوت: ';
  static const String recordErrorPrefix = 'تسجيل: ';
  static const String playErrorPrefix = 'تشغيل: ';
  static const String phoneNumberPrefix = 'الرقم: ';

  // Profil client
  static const String notLoggedIn = 'غير متصل';
  static const String newDemandTooltip = 'طلب جديد';
  static const String statDemands = 'طلبات';
  static const String statFollows = 'متابَعون';
  static const String myDemandsSection = 'طلباتي';
  static const String noDemandsHint = 'لا طلبات. اضغط + لنشر طلب.';
  static const String editProfile = 'تعديل الملف';
  static const String logout = 'تسجيل الخروج';
  static const String deleteRequestTitle = 'حذف الطلب؟';
  static const String deleteRequestBody = 'لا يمكن التراجع.';
  static const String deleteAction = 'حذف';
  static const String requestDeletedSnack = 'تم حذف الطلب';
  static const String editSheetTitle = 'تعديل';
  static const String fieldFirstName = 'الاسم الأول';
  static const String fieldLastName = 'الاسم';
  static const String save = 'حفظ';
  static const String meLabel = 'أنا';
  static const String deleteTooltip = 'حذف';

  // Profil artisan (onglet)
  static const String artisanMyProfileTitle = 'ملفي كحرفي';
  static const String photoProfileUpdated = 'تم تحديث صورة الملف';
  static const String profileUpdatedSnack = 'تم تحديث الملف';
  static const String changePhotoTooltip = 'تغيير الصورة';
  static const String followersLabel = 'متابعون';
  static const String clientDemandsCountLabel = 'طلبات الزبائن';
  static const String coordinatesSection = 'بيانات الاتصال';
  static const String emailRowLabel = 'البريد';
  static const String phoneVisibleHint = 'يظهر للزبائن للتواصل (حسب الشاشة).';
  static const String phoneFieldLabel = 'الهاتف';
  static const String phoneFieldHint = 'رقم الهاتف';
  static const String identitySection = 'الهوية';
  static const String activitySection = 'النشاط';
  static const String fieldDomainsComma = 'المجالات — مفصولة بفاصلة';
  static const String fieldDescriptionLabel = 'الوصف';
  static const String saveProfileButton = 'حفظ الملف';

  // Détail artisan
  static const String artisanDetailSubtitle = 'ملف حرفي';
  static const String trustWord = 'ثقة';
  static const String portfolioSection = 'معرض الأعمال — قبل / بعد';
  static const String noPortfolioYet = 'لا صور بعد.';

  // Fil client (carte)
  static const String publicCommentsOnPost = 'تعليقات عامة على هذا المنشور';
  static const String tooltipRemoveFavorite = 'إزالة من المفضلة';
  static const String tooltipAddFavorite = 'إضافة للمفضلة';
  static const String tooltipPrivateMessageArtisan = 'رسالة خاصة للحرفي';

  // J'aime (feuille)
  static const String likesSheetTitle = 'إعجابات';
  static const String noLikersYet = 'لا أحد بعد.';
  static const String userFallback = 'مستخدم';
}

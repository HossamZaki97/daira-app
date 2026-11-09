// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'دايرة';

  @override
  String get retry => 'حاول مجددًا';

  @override
  String get cancel => 'إلغاء';

  @override
  String get close => 'إغلاق';

  @override
  String get later => 'لاحقًا';

  @override
  String get ok => 'حسنًا';

  @override
  String get continueAction => 'متابعة';

  @override
  String get loading => 'جارٍ التحميل…';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signInTitle => 'أهلًا بعودتك';

  @override
  String get signInBody => 'سجّل الدخول لمتابعة جمعياتك.';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get requiredField => 'أكمل هذا الحقل.';

  @override
  String get invalidEmail => 'أدخل بريدًا إلكترونيًا صحيحًا.';

  @override
  String get errorOffline => 'لا يوجد اتصال. تحقّق من الإنترنت وحاول مجددًا.';

  @override
  String get errorUnavailable => 'دايرة لا تستجيب الآن. حاول بعد قليل.';

  @override
  String get errorCredentials =>
      'راجع البريد وكلمة المرور. الحساب الجديد يحتاج تأكيد البريد أولًا.';

  @override
  String get errorSuspended => 'هذا الحساب موقوف. تواصل مع دعم دايرة.';

  @override
  String get errorSessionEnded => 'انتهت جلستك. سجّل الدخول مجددًا.';

  @override
  String get errorConflict =>
      'تغيّرت البيانات في الأثناء. حدّثناها — راجعها وحاول مجددًا.';

  @override
  String get errorForbidden => 'لا يمكنك تنفيذ هذا الإجراء في هذه الجمعية.';

  @override
  String get errorRateLimited => 'محاولات كثيرة. انتظر قليلًا ثم حاول مجددًا.';

  @override
  String get errorInvalidInput => 'راجع البيانات المحددة.';

  @override
  String get errorNotFound => 'هذا العنصر لم يعد متاحًا.';

  @override
  String get errorCircleSuspended => 'هذه الجمعية موقوفة من دعم دايرة.';

  @override
  String get errorGeneric => 'حدث خطأ. حاول مجددًا.';

  @override
  String get maintenanceTitle => 'دايرة تحت الصيانة';

  @override
  String get maintenanceBody =>
      'نحسّن الخدمة الآن. بياناتك في أمان — عُد بعد قليل.';

  @override
  String maintenanceUntil(String until) {
    return 'العودة المتوقعة: $until';
  }

  @override
  String get updateRequiredTitle => 'حدّث دايرة للمتابعة';

  @override
  String get updateRequiredBody =>
      'هذا الإصدار لم يعد مدعومًا. حدّث التطبيق من المتجر لتواصل استخدام دايرة.';

  @override
  String get updateAvailableTitle => 'يتوفر إصدار جديد';

  @override
  String updateAvailableBody(String version) {
    return 'الإصدار $version متاح الآن في المتجر.';
  }

  @override
  String updateRequiredFrom(String date) {
    return 'سيصبح إلزاميًا من $date';
  }

  @override
  String get updateNow => 'تحديث';

  @override
  String get whatsNew => 'الجديد';

  @override
  String get offlineTitle => 'لا يوجد اتصال';

  @override
  String get offlineBody => 'دايرة تحتاج الإنترنت لتبقى جمعياتك محدّثة.';

  @override
  String get unavailableTitle => 'تعذّر الوصول إلى دايرة';

  @override
  String get unavailableBody => 'لم تستجب الخدمة. حاول مجددًا بعد لحظات.';

  @override
  String get obligationPending => 'مستحق';

  @override
  String get obligationReported => 'بانتظار التأكيد';

  @override
  String get obligationApproved => 'مؤكَّد';

  @override
  String get obligationOverdue => 'متأخر';

  @override
  String get actionPaid => 'دفعت القسط';

  @override
  String get actionReceived => 'وصلني';

  @override
  String get actionNotReceived => 'لم يصلني';

  @override
  String get actionPayout => 'سلّمت المبلغ';

  @override
  String get actionReceipt => 'استلمت';

  @override
  String get circleDraft => 'مسودة';

  @override
  String get circleActive => 'نشطة';

  @override
  String get circleSuspended => 'موقوفة';

  @override
  String get circleCompleted => 'مكتملة';

  @override
  String get circleCancelled => 'ملغاة';

  @override
  String get roundCollecting => 'جارٍ التحصيل';

  @override
  String get roundReady => 'جاهزة للتسليم';

  @override
  String get roundPayoutReported => 'بانتظار الاستلام';

  @override
  String get roundCompleted => 'مكتملة';

  @override
  String get language => 'اللغة';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get appearance => 'المظهر';

  @override
  String get themeSystem => 'حسب الجهاز';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get previewTitle => 'أساس دايرة';

  @override
  String get previewBody =>
      'هذه النسخة لاختبار التصميم الجديد والاتصال بالخادم. الشاشات الكاملة في المرحلة القادمة.';

  @override
  String signedInAs(String name) {
    return 'مسجّل باسم $name';
  }

  @override
  String get serverStatus => 'الخادم';

  @override
  String get connected => 'متصل';

  @override
  String activeCirclesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count جمعية نشطة',
      many: '$count جمعية نشطة',
      few: '$count جمعيات نشطة',
      two: 'جمعيتان نشطتان',
      one: 'جمعية نشطة واحدة',
      zero: 'لا توجد جمعيات نشطة',
    );
    return '$_temp0';
  }

  @override
  String actionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إجراء مطلوب منك',
      many: '$count إجراءً مطلوبًا منك',
      few: '$count إجراءات مطلوبة منك',
      two: 'إجراءان مطلوبان منك',
      one: 'إجراء واحد مطلوب منك',
      zero: 'لا شيء مطلوب منك الآن',
    );
    return '$_temp0';
  }

  @override
  String get componentsTitle => 'المكوّنات';

  @override
  String get emptyCirclesTitle => 'لا توجد جمعيات بعد';

  @override
  String get emptyCirclesBody =>
      'أنشئ جمعية لمجموعتك، أو انضم لجمعية برمز دعوة.';

  @override
  String get createCircle => 'إنشاء جمعية';

  @override
  String get joinWithCode => 'الانضمام برمز';

  @override
  String roundOf(int number, int total) {
    return 'الدور $number من $total';
  }

  @override
  String dueOn(String date) {
    return 'يستحق $date';
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'LEDCare OS'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In tr, this message translates to:
  /// **'LED ekran teknik servis platformu'**
  String get appTagline;

  /// No description provided for @loading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor…'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get close;

  /// No description provided for @errorGeneric.
  ///
  /// In tr, this message translates to:
  /// **'Beklenmeyen bir hata oluştu.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In tr, this message translates to:
  /// **'Sunucuya ulaşılamadı. Bağlantınızı kontrol edin.'**
  String get errorNetwork;

  /// No description provided for @errorForbidden.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem için yetkiniz yok.'**
  String get errorForbidden;

  /// No description provided for @errorNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt bulunamadı.'**
  String get errorNotFound;

  /// No description provided for @errorStale.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt güncel değil'**
  String get errorStale;

  /// No description provided for @errorStaleDetail.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt başka biri tarafından güncellendi. Güncel hali yüklendi.'**
  String get errorStaleDetail;

  /// No description provided for @errorTooManyAttempts.
  ///
  /// In tr, this message translates to:
  /// **'Çok fazla deneme yapıldı. Lütfen biraz bekleyin.'**
  String get errorTooManyAttempts;

  /// No description provided for @loginTitle.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yap'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınızla oturum açın'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get passwordLabel;

  /// No description provided for @loginButton.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yap'**
  String get loginButton;

  /// No description provided for @sessionExpired.
  ///
  /// In tr, this message translates to:
  /// **'Oturumunuzun süresi doldu. Lütfen tekrar giriş yapın.'**
  String get sessionExpired;

  /// No description provided for @loginInvalid.
  ///
  /// In tr, this message translates to:
  /// **'E-posta veya şifre hatalı.'**
  String get loginInvalid;

  /// No description provided for @validationEmailRequired.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresinizi girin.'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir e-posta adresi girin.'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In tr, this message translates to:
  /// **'Şifrenizi girin.'**
  String get validationPasswordRequired;

  /// No description provided for @showPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifreyi göster'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifreyi gizle'**
  String get hidePassword;

  /// No description provided for @navRequests.
  ///
  /// In tr, this message translates to:
  /// **'Talepler'**
  String get navRequests;

  /// No description provided for @navMyRequests.
  ///
  /// In tr, this message translates to:
  /// **'Taleplerim'**
  String get navMyRequests;

  /// No description provided for @navJobs.
  ///
  /// In tr, this message translates to:
  /// **'İşlerim'**
  String get navJobs;

  /// No description provided for @navProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @myRequestsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Taleplerim'**
  String get myRequestsTitle;

  /// No description provided for @allRequestsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Servis talepleri'**
  String get allRequestsTitle;

  /// No description provided for @jobsTitle.
  ///
  /// In tr, this message translates to:
  /// **'İşlerim'**
  String get jobsTitle;

  /// No description provided for @newRequest.
  ///
  /// In tr, this message translates to:
  /// **'Yeni talep'**
  String get newRequest;

  /// No description provided for @filterAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get filterAll;

  /// No description provided for @emptyRequests.
  ///
  /// In tr, this message translates to:
  /// **'Henüz servis talebi yok.'**
  String get emptyRequests;

  /// No description provided for @emptyRequestsCustomer.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir servis talebiniz yok. Arıza veya bakım ihtiyacınızı yeni talep oluşturarak iletebilirsiniz.'**
  String get emptyRequestsCustomer;

  /// No description provided for @emptyRequestsFiltered.
  ///
  /// In tr, this message translates to:
  /// **'Bu durumda talep bulunmuyor.'**
  String get emptyRequestsFiltered;

  /// No description provided for @emptyTechnicianJobs.
  ///
  /// In tr, this message translates to:
  /// **'Size atanmış iş bulunmuyor'**
  String get emptyTechnicianJobs;

  /// No description provided for @emptyTechnicianJobsDetail.
  ///
  /// In tr, this message translates to:
  /// **'Size bir iş atandığında burada görünecek.'**
  String get emptyTechnicianJobsDetail;

  /// No description provided for @listTruncated.
  ///
  /// In tr, this message translates to:
  /// **'{shown} / {total} talep gösteriliyor'**
  String listTruncated(int shown, int total);

  /// No description provided for @createRequestTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni servis talebi'**
  String get createRequestTitle;

  /// No description provided for @titleLabel.
  ///
  /// In tr, this message translates to:
  /// **'Başlık'**
  String get titleLabel;

  /// No description provided for @titleHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn. Ekranın sol alt bölümü yanmıyor'**
  String get titleHint;

  /// No description provided for @descriptionLabel.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In tr, this message translates to:
  /// **'Arızayı, ekranın konumunu ve ne zamandan beri sürdüğünü anlatın.'**
  String get descriptionHint;

  /// No description provided for @submitRequest.
  ///
  /// In tr, this message translates to:
  /// **'Talebi gönder'**
  String get submitRequest;

  /// No description provided for @validationTitleLength.
  ///
  /// In tr, this message translates to:
  /// **'Başlık 5 ile 150 karakter arasında olmalı.'**
  String get validationTitleLength;

  /// No description provided for @validationDescriptionLength.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama 10 ile 4000 karakter arasında olmalı.'**
  String get validationDescriptionLength;

  /// No description provided for @requestCreated.
  ///
  /// In tr, this message translates to:
  /// **'Talebiniz oluşturuldu.'**
  String get requestCreated;

  /// No description provided for @detailTitle.
  ///
  /// In tr, this message translates to:
  /// **'Talep detayı'**
  String get detailTitle;

  /// No description provided for @descriptionSection.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama'**
  String get descriptionSection;

  /// No description provided for @historySection.
  ///
  /// In tr, this message translates to:
  /// **'Durum geçmişi'**
  String get historySection;

  /// No description provided for @actionsSection.
  ///
  /// In tr, this message translates to:
  /// **'İşlemler'**
  String get actionsSection;

  /// No description provided for @customerLabel.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri'**
  String get customerLabel;

  /// No description provided for @createdLabel.
  ///
  /// In tr, this message translates to:
  /// **'Oluşturulma'**
  String get createdLabel;

  /// No description provided for @updatedLabel.
  ///
  /// In tr, this message translates to:
  /// **'Son güncelleme'**
  String get updatedLabel;

  /// No description provided for @historyCreated.
  ///
  /// In tr, this message translates to:
  /// **'Talep oluşturuldu'**
  String get historyCreated;

  /// No description provided for @cancelRequest.
  ///
  /// In tr, this message translates to:
  /// **'Talebi iptal et'**
  String get cancelRequest;

  /// No description provided for @cancelRequestConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu talebi iptal etmek istediğinize emin misiniz?'**
  String get cancelRequestConfirm;

  /// No description provided for @changeStatusTo.
  ///
  /// In tr, this message translates to:
  /// **'{status} olarak işaretle'**
  String changeStatusTo(String status);

  /// No description provided for @noteLabel.
  ///
  /// In tr, this message translates to:
  /// **'Not (isteğe bağlı)'**
  String get noteLabel;

  /// No description provided for @noteTooLong.
  ///
  /// In tr, this message translates to:
  /// **'Not en fazla 1000 karakter olabilir.'**
  String get noteTooLong;

  /// No description provided for @confirm.
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get confirm;

  /// No description provided for @statusChanged.
  ///
  /// In tr, this message translates to:
  /// **'Durum güncellendi: {status}'**
  String statusChanged(String status);

  /// No description provided for @noActions.
  ///
  /// In tr, this message translates to:
  /// **'Bu talep için yapabileceğiniz bir işlem yok.'**
  String get noActions;

  /// No description provided for @profileTitle.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get profileTitle;

  /// No description provided for @organizationLabel.
  ///
  /// In tr, this message translates to:
  /// **'Organizasyon'**
  String get organizationLabel;

  /// No description provided for @rolesLabel.
  ///
  /// In tr, this message translates to:
  /// **'Roller'**
  String get rolesLabel;

  /// No description provided for @logout.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış yap'**
  String get logout;

  /// No description provided for @realtimeConnected.
  ///
  /// In tr, this message translates to:
  /// **'Canlı güncellemeler açık'**
  String get realtimeConnected;

  /// No description provided for @realtimeConnecting.
  ///
  /// In tr, this message translates to:
  /// **'Canlı güncellemelere bağlanılıyor'**
  String get realtimeConnecting;

  /// No description provided for @realtimeDisconnected.
  ///
  /// In tr, this message translates to:
  /// **'Canlı güncellemeler kapalı'**
  String get realtimeDisconnected;

  /// No description provided for @noAccessTitle.
  ///
  /// In tr, this message translates to:
  /// **'Erişim tanımlı değil'**
  String get noAccessTitle;

  /// No description provided for @noAccessDetail.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınıza bu uygulamada kullanılabilecek bir rol atanmamış. Yöneticinizle iletişime geçin.'**
  String get noAccessDetail;

  /// No description provided for @statusNew.
  ///
  /// In tr, this message translates to:
  /// **'Yeni'**
  String get statusNew;

  /// No description provided for @statusInReview.
  ///
  /// In tr, this message translates to:
  /// **'İnceleniyor'**
  String get statusInReview;

  /// No description provided for @statusInProgress.
  ///
  /// In tr, this message translates to:
  /// **'İşlemde'**
  String get statusInProgress;

  /// No description provided for @statusWaitingForCustomer.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri Yanıtı Bekleniyor'**
  String get statusWaitingForCustomer;

  /// No description provided for @statusResolved.
  ///
  /// In tr, this message translates to:
  /// **'Çözüldü'**
  String get statusResolved;

  /// No description provided for @statusClosed.
  ///
  /// In tr, this message translates to:
  /// **'Kapatıldı'**
  String get statusClosed;

  /// No description provided for @statusCancelled.
  ///
  /// In tr, this message translates to:
  /// **'İptal Edildi'**
  String get statusCancelled;

  /// No description provided for @roleServiceManager.
  ///
  /// In tr, this message translates to:
  /// **'Servis Yöneticisi'**
  String get roleServiceManager;

  /// No description provided for @roleDispatcher.
  ///
  /// In tr, this message translates to:
  /// **'Operasyon Sorumlusu'**
  String get roleDispatcher;

  /// No description provided for @roleRemoteSupportTechnician.
  ///
  /// In tr, this message translates to:
  /// **'Uzaktan Destek Teknisyeni'**
  String get roleRemoteSupportTechnician;

  /// No description provided for @roleFieldTechnician.
  ///
  /// In tr, this message translates to:
  /// **'Saha Teknisyeni'**
  String get roleFieldTechnician;

  /// No description provided for @roleCustomer.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri'**
  String get roleCustomer;

  /// No description provided for @rolePlatformSuperAdmin.
  ///
  /// In tr, this message translates to:
  /// **'Platform Yöneticisi'**
  String get rolePlatformSuperAdmin;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

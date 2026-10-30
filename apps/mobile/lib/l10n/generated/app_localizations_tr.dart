// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'LEDCare OS';

  @override
  String get appTagline => 'LED ekran teknik servis platformu';

  @override
  String get loading => 'Yükleniyor…';

  @override
  String get retry => 'Tekrar dene';

  @override
  String get cancel => 'Vazgeç';

  @override
  String get close => 'Kapat';

  @override
  String get errorGeneric => 'Beklenmeyen bir hata oluştu.';

  @override
  String get errorNetwork => 'Sunucuya ulaşılamadı. Bağlantınızı kontrol edin.';

  @override
  String get errorForbidden => 'Bu işlem için yetkiniz yok.';

  @override
  String get errorNotFound => 'Kayıt bulunamadı.';

  @override
  String get errorStale => 'Kayıt güncel değil';

  @override
  String get errorStaleDetail =>
      'Kayıt başka biri tarafından güncellendi. Güncel hali yüklendi.';

  @override
  String get errorTooManyAttempts =>
      'Çok fazla deneme yapıldı. Lütfen biraz bekleyin.';

  @override
  String get loginTitle => 'Giriş yap';

  @override
  String get loginSubtitle => 'Hesabınızla oturum açın';

  @override
  String get emailLabel => 'E-posta';

  @override
  String get passwordLabel => 'Şifre';

  @override
  String get loginButton => 'Giriş yap';

  @override
  String get sessionExpired =>
      'Oturumunuzun süresi doldu. Lütfen tekrar giriş yapın.';

  @override
  String get loginInvalid => 'E-posta veya şifre hatalı.';

  @override
  String get validationEmailRequired => 'E-posta adresinizi girin.';

  @override
  String get validationEmailInvalid => 'Geçerli bir e-posta adresi girin.';

  @override
  String get validationPasswordRequired => 'Şifrenizi girin.';

  @override
  String get showPassword => 'Şifreyi göster';

  @override
  String get hidePassword => 'Şifreyi gizle';

  @override
  String get navRequests => 'Talepler';

  @override
  String get navMyRequests => 'Taleplerim';

  @override
  String get navJobs => 'İşlerim';

  @override
  String get navProfile => 'Profil';

  @override
  String get myRequestsTitle => 'Taleplerim';

  @override
  String get allRequestsTitle => 'Servis talepleri';

  @override
  String get jobsTitle => 'İşlerim';

  @override
  String get newRequest => 'Yeni talep';

  @override
  String get filterAll => 'Tümü';

  @override
  String get emptyRequests => 'Henüz servis talebi yok.';

  @override
  String get emptyRequestsCustomer =>
      'Henüz bir servis talebiniz yok. Arıza veya bakım ihtiyacınızı yeni talep oluşturarak iletebilirsiniz.';

  @override
  String get emptyRequestsFiltered => 'Bu durumda talep bulunmuyor.';

  @override
  String get emptyTechnicianJobs => 'Size atanmış iş bulunmuyor';

  @override
  String get emptyTechnicianJobsDetail =>
      'Size bir iş atandığında burada görünecek.';

  @override
  String listTruncated(int shown, int total) {
    return '$shown / $total talep gösteriliyor';
  }

  @override
  String get createRequestTitle => 'Yeni servis talebi';

  @override
  String get titleLabel => 'Başlık';

  @override
  String get titleHint => 'Örn. Ekranın sol alt bölümü yanmıyor';

  @override
  String get descriptionLabel => 'Açıklama';

  @override
  String get descriptionHint =>
      'Arızayı, ekranın konumunu ve ne zamandan beri sürdüğünü anlatın.';

  @override
  String get submitRequest => 'Talebi gönder';

  @override
  String get validationTitleLength =>
      'Başlık 5 ile 150 karakter arasında olmalı.';

  @override
  String get validationDescriptionLength =>
      'Açıklama 10 ile 4000 karakter arasında olmalı.';

  @override
  String get requestCreated => 'Talebiniz oluşturuldu.';

  @override
  String get detailTitle => 'Talep detayı';

  @override
  String get descriptionSection => 'Açıklama';

  @override
  String get historySection => 'Durum geçmişi';

  @override
  String get actionsSection => 'İşlemler';

  @override
  String get customerLabel => 'Müşteri';

  @override
  String get createdLabel => 'Oluşturulma';

  @override
  String get updatedLabel => 'Son güncelleme';

  @override
  String get historyCreated => 'Talep oluşturuldu';

  @override
  String get cancelRequest => 'Talebi iptal et';

  @override
  String get cancelRequestConfirm =>
      'Bu talebi iptal etmek istediğinize emin misiniz?';

  @override
  String changeStatusTo(String status) {
    return '$status olarak işaretle';
  }

  @override
  String get noteLabel => 'Not (isteğe bağlı)';

  @override
  String get noteTooLong => 'Not en fazla 1000 karakter olabilir.';

  @override
  String get confirm => 'Onayla';

  @override
  String statusChanged(String status) {
    return 'Durum güncellendi: $status';
  }

  @override
  String get noActions => 'Bu talep için yapabileceğiniz bir işlem yok.';

  @override
  String get profileTitle => 'Profil';

  @override
  String get organizationLabel => 'Organizasyon';

  @override
  String get rolesLabel => 'Roller';

  @override
  String get logout => 'Çıkış yap';

  @override
  String get realtimeConnected => 'Canlı güncellemeler açık';

  @override
  String get realtimeConnecting => 'Canlı güncellemelere bağlanılıyor';

  @override
  String get realtimeDisconnected => 'Canlı güncellemeler kapalı';

  @override
  String get noAccessTitle => 'Erişim tanımlı değil';

  @override
  String get noAccessDetail =>
      'Hesabınıza bu uygulamada kullanılabilecek bir rol atanmamış. Yöneticinizle iletişime geçin.';

  @override
  String get statusNew => 'Yeni';

  @override
  String get statusInReview => 'İnceleniyor';

  @override
  String get statusInProgress => 'İşlemde';

  @override
  String get statusWaitingForCustomer => 'Müşteri Yanıtı Bekleniyor';

  @override
  String get statusResolved => 'Çözüldü';

  @override
  String get statusClosed => 'Kapatıldı';

  @override
  String get statusCancelled => 'İptal Edildi';

  @override
  String get roleServiceManager => 'Servis Yöneticisi';

  @override
  String get roleDispatcher => 'Operasyon Sorumlusu';

  @override
  String get roleRemoteSupportTechnician => 'Uzaktan Destek Teknisyeni';

  @override
  String get roleFieldTechnician => 'Saha Teknisyeni';

  @override
  String get roleCustomer => 'Müşteri';

  @override
  String get rolePlatformSuperAdmin => 'Platform Yöneticisi';
}

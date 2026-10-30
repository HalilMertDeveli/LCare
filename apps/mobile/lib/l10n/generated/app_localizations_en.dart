// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LEDCare OS';

  @override
  String get appTagline => 'LED screen technical service platform';

  @override
  String get loading => 'Loading…';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get errorGeneric => 'Something went wrong.';

  @override
  String get errorNetwork => 'Cannot reach the server. Check your connection.';

  @override
  String get errorForbidden => 'You are not allowed to do this.';

  @override
  String get errorNotFound => 'Record not found.';

  @override
  String get errorStale => 'Record is out of date';

  @override
  String get errorStaleDetail =>
      'Someone else updated this record. The latest version has been loaded.';

  @override
  String get errorTooManyAttempts => 'Too many attempts. Please wait a moment.';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginSubtitle => 'Sign in with your account';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginButton => 'Sign in';

  @override
  String get sessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get loginInvalid => 'Incorrect email or password.';

  @override
  String get validationEmailRequired => 'Enter your email address.';

  @override
  String get validationEmailInvalid => 'Enter a valid email address.';

  @override
  String get validationPasswordRequired => 'Enter your password.';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get navRequests => 'Requests';

  @override
  String get navMyRequests => 'My requests';

  @override
  String get navJobs => 'My jobs';

  @override
  String get navProfile => 'Profile';

  @override
  String get myRequestsTitle => 'My requests';

  @override
  String get allRequestsTitle => 'Service requests';

  @override
  String get jobsTitle => 'My jobs';

  @override
  String get newRequest => 'New request';

  @override
  String get filterAll => 'All';

  @override
  String get emptyRequests => 'No service requests yet.';

  @override
  String get emptyRequestsCustomer =>
      'You have no service requests yet. Create a new request to report a fault or maintenance need.';

  @override
  String get emptyRequestsFiltered => 'No requests with this status.';

  @override
  String get emptyTechnicianJobs => 'No jobs are assigned to you';

  @override
  String get emptyTechnicianJobsDetail =>
      'Jobs assigned to you will appear here.';

  @override
  String listTruncated(int shown, int total) {
    return 'Showing $shown of $total requests';
  }

  @override
  String get createRequestTitle => 'New service request';

  @override
  String get titleLabel => 'Title';

  @override
  String get titleHint => 'e.g. Lower-left section of the screen is dark';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get descriptionHint =>
      'Describe the fault, the screen location and since when it occurs.';

  @override
  String get submitRequest => 'Submit request';

  @override
  String get validationTitleLength => 'Title must be 5 to 150 characters.';

  @override
  String get validationDescriptionLength =>
      'Description must be 10 to 4000 characters.';

  @override
  String get requestCreated => 'Your request has been created.';

  @override
  String get detailTitle => 'Request details';

  @override
  String get descriptionSection => 'Description';

  @override
  String get historySection => 'Status history';

  @override
  String get actionsSection => 'Actions';

  @override
  String get customerLabel => 'Customer';

  @override
  String get createdLabel => 'Created';

  @override
  String get updatedLabel => 'Last updated';

  @override
  String get historyCreated => 'Request created';

  @override
  String get cancelRequest => 'Cancel request';

  @override
  String get cancelRequestConfirm =>
      'Are you sure you want to cancel this request?';

  @override
  String changeStatusTo(String status) {
    return 'Mark as $status';
  }

  @override
  String get noteLabel => 'Note (optional)';

  @override
  String get noteTooLong => 'Note can be at most 1000 characters.';

  @override
  String get confirm => 'Confirm';

  @override
  String statusChanged(String status) {
    return 'Status updated: $status';
  }

  @override
  String get noActions => 'There are no actions available for this request.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get organizationLabel => 'Organization';

  @override
  String get rolesLabel => 'Roles';

  @override
  String get logout => 'Sign out';

  @override
  String get realtimeConnected => 'Live updates on';

  @override
  String get realtimeConnecting => 'Connecting to live updates';

  @override
  String get realtimeDisconnected => 'Live updates off';

  @override
  String get noAccessTitle => 'No access configured';

  @override
  String get noAccessDetail =>
      'Your account has no role usable in this app. Contact your administrator.';

  @override
  String get statusNew => 'New';

  @override
  String get statusInReview => 'In review';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusWaitingForCustomer => 'Waiting for customer';

  @override
  String get statusResolved => 'Resolved';

  @override
  String get statusClosed => 'Closed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get roleServiceManager => 'Service manager';

  @override
  String get roleDispatcher => 'Dispatcher';

  @override
  String get roleRemoteSupportTechnician => 'Remote support technician';

  @override
  String get roleFieldTechnician => 'Field technician';

  @override
  String get roleCustomer => 'Customer';

  @override
  String get rolePlatformSuperAdmin => 'Platform administrator';
}

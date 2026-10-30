import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/realtime/refresh_signal.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/service_request_providers.dart';

/// Client-side rules mirroring `CreateServiceRequestRequest` in openapi.json.
abstract final class RequestValidation {
  static const titleMin = 5;
  static const titleMax = 150;
  static const descriptionMin = 10;
  static const descriptionMax = 4000;
  static const noteMax = 1000;

  static bool titleValid(String? v) {
    final n = (v ?? '').trim().length;
    return n >= titleMin && n <= titleMax;
  }

  static bool descriptionValid(String? v) {
    final n = (v ?? '').trim().length;
    return n >= descriptionMin && n <= descriptionMax;
  }
}

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  bool _submitting = false;
  String? _formError;
  Map<String, List<String>> _serverErrors = const {};

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _serverErrors = const {};
      _formError = null;
    });
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      final created = await ref.read(serviceRequestRepositoryProvider).create(
            title: _title.text.trim(),
            description: _description.text.trim(),
          );
      if (!mounted) return;
      ref.read(refreshSignalProvider.notifier).bump();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.requestCreated)));
      context.pushReplacement('${Routes.customerRequests}/${created.id}');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.kind == ApiErrorKind.validation && e.fieldErrors.isNotEmpty) {
          _serverErrors = e.fieldErrors;
          final unmatched = e.fieldErrors.keys.where((k) => k != 'title' && k != 'description');
          if (unmatched.isNotEmpty) {
            _formError = unmatched.map((k) => e.fieldErrors[k]!.join(' ')).join('\n');
          }
        } else {
          _formError = errorMessage(l10n, e);
        }
      });
      _formKey.currentState!.validate();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _server(String field) {
    final errors = _serverErrors[field];
    return (errors == null || errors.isEmpty) ? null : errors.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      key: const Key('createRequestScreen'),
      appBar: AppBar(title: Text(l10n.createRequestTitle)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_formError != null)
                Container(
                  key: const Key('createRequestError'),
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formError!,
                    style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                  ),
                ),
              TextFormField(
                key: const Key('titleField'),
                controller: _title,
                enabled: !_submitting,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                maxLength: RequestValidation.titleMax,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                decoration: InputDecoration(
                  labelText: l10n.titleLabel,
                  hintText: l10n.titleHint,
                ),
                onChanged: (_) {
                  if (_serverErrors.containsKey('title')) {
                    setState(() => _serverErrors = {..._serverErrors}..remove('title'));
                  }
                },
                validator: (v) => !RequestValidation.titleValid(v)
                    ? l10n.validationTitleLength
                    : _server('title'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('descriptionField'),
                controller: _description,
                enabled: !_submitting,
                minLines: 5,
                maxLines: 12,
                maxLength: RequestValidation.descriptionMax,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  labelText: l10n.descriptionLabel,
                  hintText: l10n.descriptionHint,
                  alignLabelWithHint: true,
                ),
                onChanged: (_) {
                  if (_serverErrors.containsKey('description')) {
                    setState(() => _serverErrors = {..._serverErrors}..remove('description'));
                  }
                },
                validator: (v) => !RequestValidation.descriptionValid(v)
                    ? l10n.validationDescriptionLength
                    : _server('description'),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const Key('submitRequestButton'),
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(l10n.submitRequest),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

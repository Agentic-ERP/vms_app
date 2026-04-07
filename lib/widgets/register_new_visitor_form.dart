import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/create_visitor_request.dart';
import '../providers/add_visitor_photo_provider.dart';
import '../providers/create_visitor_provider.dart';
import '../theme/app_theme.dart';

/// Register new visitor form backed by create-visitor API.
class RegisterNewVisitorForm extends ConsumerStatefulWidget {
  const RegisterNewVisitorForm({super.key});

  @override
  ConsumerState<RegisterNewVisitorForm> createState() =>
      _RegisterNewVisitorFormState();
}

class _RegisterNewVisitorFormState extends ConsumerState<RegisterNewVisitorForm> {
  final ImagePicker _picker = ImagePicker();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  Uint8List? _photoBytes;
  String _photoFilename = 'visitor_photo.jpg';

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1280,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;
      final fileName = file.name.isNotEmpty ? file.name : _photoFilename;
      setState(() {
        _photoBytes = bytes;
        _photoFilename = fileName;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open ${source.name}: $e')),
      );
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _companyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final submitAsync = ref.watch(createVisitorControllerProvider);
    final uploadAsync = ref.watch(addVisitorPhotoControllerProvider);
    final isBusy = submitAsync.isLoading || uploadAsync.isLoading;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Visitor Registration',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please fill in your details to register as a visitor',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'All fields are mandatory',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 20),
            _requiredLabel(context, 'Full Name'),
            const SizedBox(height: 8),
            TextField(
              controller: _fullNameCtrl,
              decoration: InputDecoration(hintText: 'Enter your full name'),
            ),
            const SizedBox(height: 16),
            _requiredLabel(context, 'Phone Number'),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(hintText: 'Enter your phone number'),
            ),
            const SizedBox(height: 16),
            _requiredLabel(context, 'Company Name'),
            const SizedBox(height: 8),
            TextField(
              controller: _companyCtrl,
              decoration: InputDecoration(hintText: 'Enter your company name'),
            ),
            const SizedBox(height: 16),
            _requiredLabel(context, 'Photo'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _photoBox(
                    context: context,
                    icon: Icons.upload_file_outlined,
                    text: 'Click to upload photo',
                    onTap: () => _pickPhoto(ImageSource.gallery),
                    preview: _photoBytes,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _photoBox(
                    context: context,
                    icon: Icons.camera_alt_outlined,
                    text: 'Take Photo',
                    onTap: () => _pickPhoto(ImageSource.camera),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: VmsColors.registerMuted,
                  foregroundColor: Colors.white,
                ),
                onPressed: isBusy ? null : _submit,
                child: isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Register Visitor'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final fullName = _fullNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final company = _companyCtrl.text.trim();
    final photo = _photoBytes;

    if (fullName.isEmpty || phone.isEmpty || company.isEmpty || photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all mandatory fields')),
      );
      return;
    }

    const embeddings = <double>[0.12, -0.34, 0.56, 0.78, -0.91];
    final request = CreateVisitorRequest(
      fullName: fullName,
      phoneNumber: phone,
      companyName: company,
      faceEmbeddings: embeddings,
    );

    try {
      final response = await ref
          .read(createVisitorControllerProvider.notifier)
          .submit(request);
      if (!mounted) return;
      if (response.isSuccess) {
        final createdVisitorId = response.createdVisitorId;
        if (createdVisitorId == null || createdVisitorId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Visitor created but visitor_id missing')),
          );
          return;
        }

        final photoResponse = await ref
            .read(addVisitorPhotoControllerProvider.notifier)
            .submit(
              visitorId: createdVisitorId,
              photoBytes: photo,
              filename: _photoFilename,
            );
        if (!mounted) return;
        if (!photoResponse.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Photo upload failed: ${photoResponse.status}')),
          );
          return;
        }

        setState(() {
          _fullNameCtrl.clear();
          _phoneCtrl.clear();
          _companyCtrl.clear();
          _photoBytes = null;
          _photoFilename = 'visitor_photo.jpg';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Visitor registered + photo uploaded (${response.status})',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Register failed: ${response.status}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Widget _requiredLabel(BuildContext context, String text) {
    return Text.rich(
      TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
        children: [
          TextSpan(text: text),
          TextSpan(
            text: ' *',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ),
    );
  }

  Widget _photoBox({
    required BuildContext context,
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Uint8List? preview,
  }) {
    final outline = Theme.of(context).colorScheme.outline;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Material(
      color: VmsColors.fieldFill,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            border: Border.all(color: outline, width: 1.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: preview != null
              ? Image.memory(
                  preview,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: muted),
                      const SizedBox(height: 6),
                      Text(
                        text,
                        style: TextStyle(color: muted, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

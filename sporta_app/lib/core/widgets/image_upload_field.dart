import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';
import '../di/service_locator.dart';
import '../network/api_endpoints.dart';
import '../state/app_scope.dart';
import '../../features/auth/data/models/api_exception.dart';

/// A reusable image field that picks an image from the device (camera/gallery),
/// uploads it to the server, and reports back the stored relative URL
/// (e.g. `/uploads/images/xxx.jpg`) via [onChanged].
class ImageUploadField extends StatefulWidget {
  const ImageUploadField({
    super.key,
    required this.value,
    required this.onChanged,
    this.height = 160,
    this.label,
  });

  /// Current stored URL (relative `/uploads/...` or absolute), or null.
  final String? value;
  final ValueChanged<String?> onChanged;
  final double height;
  final String? label;

  @override
  State<ImageUploadField> createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends State<ImageUploadField> {
  final _dio = getIt<Dio>();
  bool _uploading = false;

  Future<void> _pick(ImageSource source) async {
    final picked = await ImagePicker()
        .pickImage(source: source, maxWidth: 1280, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() => _uploading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(picked.path),
      });
      final res = await _dio.post(ApiEndpoints.uploadImage, data: form);
      final data = (res.data['data'] ?? res.data) as Map<String, dynamic>;
      final url = data['url']?.toString();
      if (!mounted) return;
      setState(() => _uploading = false);
      if (url != null) widget.onChanged(url);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      final err = e.response != null
          ? ApiException.fromResponse(e.response!)
          : ApiException.network;
      messenger.showSnackBar(SnackBar(content: Text(err.display)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploading = false);
      messenger.showSnackBar(
          SnackBar(content: Text(context.tr('تعذّر رفع الصورة'))));
    }
  }

  void _chooseSource() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: Directionality.of(context),
        child: SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.primary),
                title: Text(context.tr('اختيار من المعرض')),
                onTap: () {
                  Navigator.pop(ctx);
                  _pick(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.primary),
                title: Text(context.tr('التقاط صورة')),
                onTap: () {
                  Navigator.pop(ctx);
                  _pick(ImageSource.camera);
                },
              ),
              if (widget.value != null && widget.value!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: AppColors.destructive),
                  title: Text(context.tr('إزالة الصورة'),
                      style: const TextStyle(color: AppColors.destructive)),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onChanged(null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.value != null && widget.value!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(context.tr(widget.label!),
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSizes.sm),
        ],
        GestureDetector(
          onTap: _uploading ? null : _chooseSource,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            child: SizedBox(
              height: widget.height,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    Image.network(
                      ApiEndpoints.fileUrl(widget.value!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder(),
                    )
                  else
                    _placeholder(),
                  if (_uploading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.35),
                      child: const Center(
                          child: CircularProgressIndicator(color: Colors.white)),
                    ),
                  // Edit badge.
                  PositionedDirectional(
                    bottom: AppSizes.sm,
                    end: AppSizes.sm,
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.sm),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.photo_camera_outlined,
                          size: AppSizes.iconSm, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFEFF6FF),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_photo_alternate_outlined,
                  size: 40, color: AppColors.primary),
              const SizedBox(height: AppSizes.xs),
              Text(context.tr('إضافة صورة من الجهاز'),
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.primary)),
            ],
          ),
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/payment/payment_config.dart';
import '../../../../core/state/app_scope.dart';
import '../../../../core/widgets/skeleton.dart';

/// Hosts FINY's checkout page for a wallet top-up.
///
/// Pops `true` once the customer reaches the callback URL — meaning the hosted
/// page finished — and `null` if they back out. That result says the *page* is
/// done, not that the money moved: the backend re-asks FINY for the real status
/// before it credits anything.
class FinyCheckoutPage extends StatefulWidget {
  const FinyCheckoutPage({super.key, required this.session});

  final TopUpSession session;

  @override
  State<FinyCheckoutPage> createState() => _FinyCheckoutPageState();
}

class _FinyCheckoutPageState extends State<FinyCheckoutPage> {
  late final WebViewController _controller;
  bool _loading = true;

  /// Guards against popping twice — the callback URL fires both a navigation
  /// request and, on some platforms, a page-started event.
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (_isCallback(url)) _finish();
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) {
            // The callback URL is a marker, not a page: it belongs to a domain
            // that need not resolve at all. Letting it load would show the
            // customer a browser error at the exact moment they succeeded.
            if (_isCallback(request.url)) {
              _finish();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.session.redirectUrl));
  }

  bool _isCallback(String url) =>
      widget.session.callbackUrl.isNotEmpty &&
      url.startsWith(widget.session.callbackUrl);

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.secondary,
        title: Text(
          context.tr('إتمام الدفع'),
          style: AppTextStyles.heading3.copyWith(color: AppColors.secondary),
        ),
      ),
      // صفحة الدفع صفحة ويب تملأ الشاشة؛ نمنع شريط تنقّل النظام السفلي من
      // تغطية أزرارها.
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading)
              Container(
                color: AppColors.background,
                child: BrandedLoader(
                  label: context.tr('جارٍ فتح صفحة الدفع الآمنة…'),
                  icon: Icons.lock_outline,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

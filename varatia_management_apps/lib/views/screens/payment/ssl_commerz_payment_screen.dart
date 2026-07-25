import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_theme.dart';

class SslCommerzPaymentScreen extends StatefulWidget {
  const SslCommerzPaymentScreen({super.key, required this.paymentUrl});

  final String paymentUrl;

  @override
  State<SslCommerzPaymentScreen> createState() =>
      _SslCommerzPaymentScreenState();
}

class _SslCommerzPaymentScreenState extends State<SslCommerzPaymentScreen> {
  late final WebViewController _controller;
  int _loadingProgress = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _hasError = false;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _loadingProgress = 0;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            // Ignore system/cache resource issues
            if (error.description.contains('net::ERR_CACHE_MISS')) return;
            if (mounted) {
              setState(() {
                _hasError = true;
              });
            }
          },
          onUrlChange: (UrlChange change) {
            final url = change.url;
            if (url != null) {
              _checkPaymentRedirection(url);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkPaymentRedirection(String url) {
    if (url.contains('/api/payments/success')) {
      Navigator.of(context).pop(true);
    } else if (url.contains('/api/payments/fail') ||
        url.contains('/api/payments/cancel')) {
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('সার্ভিস চার্জ পেমেন্ট'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: Stack(
        children: [
          if (!_hasError) WebViewWidget(controller: _controller),
          if (_loadingProgress > 0)
            LinearProgressIndicator(
              value: _loadingProgress / 100.0,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          if (_hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.danger,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'পেমেন্ট পেজ লোড করা যায়নি',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'অনুগ্রহ করে আপনার ইন্টারনেট সংযোগ পরীক্ষা করুন এবং পুনরায় চেষ্টা করুন।',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _loadingProgress = 10;
                        });
                        _controller.loadRequest(Uri.parse(widget.paymentUrl));
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('পুনরায় চেষ্টা করুন'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

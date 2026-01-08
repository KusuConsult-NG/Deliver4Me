import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaystackWebviewScreen extends StatefulWidget {
  final String authorizationUrl;
  final String reference;

  const PaystackWebviewScreen({
    super.key,
    required this.authorizationUrl,
    required this.reference,
  });

  @override
  State<PaystackWebviewScreen> createState() => _PaystackWebviewScreenState();
}

class _PaystackWebviewScreenState extends State<PaystackWebviewScreen> {
  late final WebViewController _controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => isLoading = false);
            _checkPaymentStatus(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            if (_checkPaymentStatus(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  bool _checkPaymentStatus(String url) {
    // Paystack redirects to a callback URL on success
    if (url.contains('callback') || url.contains('success')) {
      // Payment successful
      Navigator.pop(context, {'success': true, 'reference': widget.reference});
      return true;
    } else if (url.contains('cancel') || url.contains('failed')) {
      // Payment failed or cancelled
      Navigator.pop(context, {'success': false, 'reference': widget.reference});
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, {
            'success': false,
            'reference': widget.reference,
            'cancelled': true
          }),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

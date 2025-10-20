import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import 'checkout_webview.dart';

class PaymentScreen extends StatelessWidget {
  final double amount;

  const PaymentScreen({Key? key, required this.amount}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Payment'),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              color: const Color(0xFF1E1E1E),
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Checkout Confirmation',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 12),
                    Text(
                        'This action will charge \$${amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text(
                        'This action will charge \$${amount.toStringAsFixed(2)} from you. Are you sure you want to proceed?',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.white70)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                            ),
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8E08EF),
                                foregroundColor: Colors.white),
                            onPressed: () async {
                              final dio = Dio(
                                  BaseOptions(baseUrl: AppConstants.baseUrl));
                              try {
                                // Build a frontend redirect URL so Stripe returns user to app
                                // On web use the browser origin. On mobile/emulator Uri.base may be file:///,
                                // which Stripe rejects. Use AppConstants.baseUrl for mobile instead.
                                // origin variable not needed because we use backend endpoints
                                // Use backend endpoints that return simple HTML pages to avoid 404 on redirect
                                final successUrl =
                                    '${AppConstants.baseUrl}/payments/success';
                                final cancelUrl =
                                    '${AppConstants.baseUrl}/payments/cancel';
                                final resp =
                                    await dio.post('/payments/checkout', data: {
                                  'amount': amount,
                                  'currency': 'usd',
                                  'successUrl': successUrl,
                                  'cancelUrl': cancelUrl,
                                });
                                final url = resp.data['url'] as String?;
                                // Log and display the URL for debugging
                                debugPrint('Checkout URL: $url');
                                if (url != null && url.isNotEmpty) {
                                  final uri = Uri.parse(url);
                                  // Show the URL in a SnackBar briefly so you can copy or inspect logs
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Checkout URL: ${uri.toString()}')));

                                  // Try external app first, then in-app webview. If both fail, show dialog with URL.
                                  try {
                                    await launchUrl(uri,
                                        mode: LaunchMode.externalApplication);
                                  } catch (eExternal) {
                                    debugPrint(
                                        'External launch failed: $eExternal');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'External browser launch failed, trying in-app webview...')));
                                    try {
                                      // Try to open inside the app using our WebView screen
                                      Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (_) => CheckoutWebView(
                                                  url: uri.toString())));
                                    } catch (eInApp) {
                                      debugPrint(
                                          'In-app webview navigation failed: $eInApp');
                                      // If we still can't open, show a dialog with the URL so user can copy/open manually
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title:
                                              const Text('Open checkout URL'),
                                          content: SelectableText(url),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(),
                                              child: const Text('Close'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(ctx).pop();
                                              },
                                              child: const Text('Copy'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Failed to create checkout session')));
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Checkout failed: $e')));
                              }
                            },
                            child: const Text('Proceed'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

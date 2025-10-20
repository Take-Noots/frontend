import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CheckoutWebView extends StatefulWidget {
  final String url;
  const CheckoutWebView({Key? key, required this.url}) : super(key: key);

  @override
  State<CheckoutWebView> createState() => _CheckoutWebViewState();
}

class _CheckoutWebViewState extends State<CheckoutWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

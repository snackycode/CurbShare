import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';

class StripeOnboardingScreen extends StatefulWidget {
  final String onboardingUrl;
  const StripeOnboardingScreen({super.key, required this.onboardingUrl});

  @override
  State<StripeOnboardingScreen> createState() => _StripeOnboardingScreenState();
}

class _StripeOnboardingScreenState extends State<StripeOnboardingScreen> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _launchStripeOnboarding();
  }

  /// Listen for deep links (return or refresh)
  void _initDeepLinks() {
    _sub = uriLinkStream.listen((Uri? uri) async {
      if (uri == null) return;

      if (uri.path == '/stripe-return') {
        await _onSuccess();
      } else if (uri.path == '/stripe-refresh') {
        _onCancel();
      }
    }, onError: (err) {
      print('Deep link error: $err');
    });
  }

  /// Open Stripe onboarding in external browser
  Future<void> _launchStripeOnboarding() async {
    // Only in Test Mode
    final testUrl = Uri.parse(
        '${widget.onboardingUrl}?prefilled_email=jenny.rosen@example.com&prefilled_name=Jenny+Rosen&prefilled_country=US');

    if (await canLaunchUrl(testUrl)) {
      await launchUrl(testUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch Stripe onboarding')),
        );
        Navigator.pop(context);
      }
    }
  }

  /// Called when onboarding succeeds
  Future<void> _onSuccess() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('User')
          .doc(uid)
          .update({'stripeOnboarded': true});
    }
    if (mounted) Navigator.pop(context, true);
  }

  /// Called when onboarding is canceled
  void _onCancel() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stripe onboarding canceled')),
      );
      Navigator.pop(context, false);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

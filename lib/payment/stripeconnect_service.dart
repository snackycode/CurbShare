import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';

class StripeConnectService {
  final FirebaseFunctions functions = FirebaseFunctions.instance;

  /// Create a new Stripe Express account for the user
  Future<String> createStripeAccount() async {
    final result = await functions.httpsCallable('createStripeAccount').call();
    final data = result.data as Map<String, dynamic>;
    return data['accountId'];
  }

  /// Generate onboarding link for the user to complete KYC
  Future<String> createAccountLink({
    required String returnUrl,
    required String refreshUrl,
  }) async {
    final result = await functions.httpsCallable('createAccountLink').call({
      'returnUrl': returnUrl,
      'refreshUrl': refreshUrl,
    });
    final data = result.data as Map<String, dynamic>;
    return data['url'];
  }

  /// Launch onboarding flow in browser
  Future<void> startOnboardingFlow() async {
    // Step 1: Create Stripe account (only first time)
    final accountId = await createStripeAccount();
    print('Stripe account created: $accountId');

    // Step 2: Create account link for onboarding
    final onboardingUrl = await createAccountLink(
      returnUrl: 'curbshare://stripe-return',
      refreshUrl: 'curbshare://stripe-refresh',
    );

    // Step 3: Launch in browser or WebView
    if (await canLaunchUrl(Uri.parse(onboardingUrl))) {
      await launchUrl(Uri.parse(onboardingUrl),
          mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch $onboardingUrl');
    }
  }

  Future<String> createStripeCustomer({
    required String name,
    required String email,
  }) async {
    final result = await functions.httpsCallable('createStripeCustomer').call({
      'name': name,
      'email': email,
    });
    return result.data['customerId'] as String;
  }

  Future<Map<String, dynamic>> createPaymentIntent({
    required String lotId,
    required String hostId,
    required DateTime start,
    required DateTime end,
    required String bookingType,
    String currency = 'usd',
  }) async {
    final result = await functions.httpsCallable('createPaymentIntent').call({
      'lotId': lotId,
      'hostId': hostId,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'bookingType': bookingType,
      'currency': currency,
    });
    return Map<String, dynamic>.from(result.data);
  }
}

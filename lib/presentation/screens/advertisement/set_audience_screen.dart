import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../data/services/advertisement_service.dart';
import '../../../data/services/auth_service.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import 'payment_screen.dart';

class SetAudienceScreen extends StatefulWidget {
  const SetAudienceScreen({Key? key}) : super(key: key);

  @override
  State<SetAudienceScreen> createState() => _SetAudienceScreenState();
}

class _SetAudienceScreenState extends State<SetAudienceScreen> {
  double _views = 1.0; // in thousands, starting at 1K

  double get _totalCost {
    if (_views <= 1.0) {
      return 10.0;
    } else {
      return 10.0 + ((_views - 1.0) * 5.0);
    }
  }

  @override
  Widget build(BuildContext context) {
  // We'll fetch the current user's latest advertisement instead of using query param
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final currentUserId = authProvider.user?.id ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Set Audience',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.titleLarge?.color),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Views Slider
            Text(
              'Select Views',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '1K',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      Text(
                        '${_views.toInt()}K',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      Text(
                        '100K',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: _views,
                    min: 1.0,
                    max: 100.0,
                    divisions: 99,
                    activeColor: Theme.of(context).colorScheme.secondary,
                    inactiveColor: isDark ? Colors.grey[600] : Colors.grey[300],
                    onChanged: (value) {
                      setState(() {
                        _views = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Cost Breakdown
            Text(
              'Cost Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'First 1K views',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      Text(
                        '\$10',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Each additional 1K views',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      Text(
                        '\$5',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Total Cost
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.secondary,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Cost',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    '\$${_totalCost.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Next Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: () async {
                    // Save payed views count to the latest advertisement created by the current user
                    if (currentUserId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Unable to determine current user')), 
                      );
                      return;
                    }

                    final authService = Provider.of<AuthService>(context, listen: false);
                    final advertisementService = AdvertisementService(authService);

                    // Fetch user's advertisements
                    final fetchResult = await advertisementService.fetchAdvertisementsByUser(currentUserId);
                    if (fetchResult['success'] != true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(fetchResult['message'] ?? 'Failed to fetch advertisements')),
                      );
                      return;
                    }

                    final List ads = fetchResult['data'] ?? [];
                    if (ads.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No advertisements found for this user')),
                      );
                      return;
                    }

                    // Convert to typed list of Advertisement if possible
                    List<dynamic> adsDynamic = ads;
                    adsDynamic.sort((a, b) {
                      try {
                        final DateTime aDate = a is Map ? DateTime.parse(a['createdAt']) : a.createdAt;
                        final DateTime bDate = b is Map ? DateTime.parse(b['createdAt']) : b.createdAt;
                        return bDate.compareTo(aDate);
                      } catch (e) {
                        return 0;
                      }
                    });

                    final latestAd = adsDynamic.first;
                    final String adId = latestAd is Map ? (latestAd['_id'] ?? latestAd['id'] ?? '') : latestAd.id;

                    final int views = _views.toInt() * 1000; // convert K to absolute
                    final result = await advertisementService.updateAdvertisement(adId, {
                      'payedViewsCount': views,
                      'remainViews': views,
                    });

                    debugPrint('Advertisement update result: $result');
                  if (result['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Audience set to ${_views.toInt()}K views.')),
                    );
                    // Navigate to payment UI (UI only for now)
                    context.pushNamed('payment', extra: {'amount': _totalCost});
                    return;
                  } else {
                      debugPrint('Failed to update advertisement: ${result['message']}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result['message'] ?? 'Failed to update advertisement')),
                      );
                      return;
                    }
                  },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8E08EF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

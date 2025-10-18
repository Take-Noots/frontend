import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../../data/services/advertisement_service.dart';
import '../../../../../data/models/advertisement_model.dart';
import '../../../../../data/services/auth_service.dart';
import '../../../../../core/providers/auth_provider.dart';
import '../../../../../core/router/route_names.dart';

class BusinessAdsTab extends StatefulWidget {
  final String userId;

  const BusinessAdsTab({Key? key, required this.userId}) : super(key: key);

  @override
  State<BusinessAdsTab> createState() => _BusinessAdsTabState();
}

class _BusinessAdsTabState extends State<BusinessAdsTab> {
  List<Advertisement> advertisements = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAdvertisements();
  }

  Future<void> _fetchAdvertisements() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final authService = AuthService(authProvider);
      final advertisementService = AdvertisementService(authService);
      final result =
          await advertisementService.fetchAdvertisementsByUser(widget.userId);

      if (result['success'] == true) {
        setState(() {
          advertisements = result['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = result['message'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load advertisements';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Text(
          errorMessage!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 16),
          advertisements.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      'No advertisements to display.',
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4.0,
                    mainAxisSpacing: 4.0,
                  ),
                  itemCount: advertisements.length + 1, // +1 for plus item
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Plus item
                      return GestureDetector(
                        onTap: () {
                          context.go(AppRoutes.createAdvertisement);
                        },
                        child: Card(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          child: const Center(
                            child: Icon(
                              Icons.add,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    } else {
                      final ad = advertisements[index - 1];
                      return GestureDetector(
                        onTap: () {
                          // TODO: Navigate to ad details
                        },
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: ad.image != null && ad.image!.isNotEmpty
                              ? Image.network(
                                  ad.image!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceVariant,
                                      child: const Center(
                                        child: Icon(Icons.image_not_supported),
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceVariant,
                                  child: const Center(
                                    child: Icon(Icons.campaign),
                                  ),
                                ),
                        ),
                      );
                    }
                  },
                ),
        ],
      ),
    );
  }
}

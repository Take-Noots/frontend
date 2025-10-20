import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../../data/services/advertisement_service.dart';
import '../../../../../data/models/advertisement_model.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../presentation/widgets/loading_screens/profile_grid_skeleton.dart';

class BusinessAdsTab extends StatefulWidget {
  final String userId;
  final ValueNotifier<bool>? refreshNotifier;

  const BusinessAdsTab({Key? key, required this.userId, this.refreshNotifier})
      : super(key: key);

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
    widget.refreshNotifier?.addListener(_onRefresh);
  }

  @override
  void dispose() {
    widget.refreshNotifier?.removeListener(_onRefresh);
    super.dispose();
  }

  void _onRefresh() {
    _fetchAdvertisements();
  }

  Future<void> _fetchAdvertisements() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    // Use an unauthenticated Dio instance for public advertisement fetching
    final dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
    final advertisementService = AdvertisementService.unauthenticated(dio);
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
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const ProfileGridSkeleton();
    }

    if (errorMessage != null) {
      return Center(
        child: Text(
          'Error: $errorMessage',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      );
    }

    if (advertisements.isEmpty) {
      return Center(
        child: Text(
          'No advertisements to display.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: advertisements.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final ad = advertisements[index];
          return GestureDetector(
            onTap: () => _showAdDialog(context, ad),
            child: ad.image != null && ad.image!.isNotEmpty
                ? Image.network(
                    ad.image!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
                  ),
          );
        },
      ),
    );
  }

  void _showAdDialog(BuildContext context, Advertisement ad) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AdDetails',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) {
        return SafeArea(
          child: GestureDetector(
            onTap: () => Navigator.of(ctx).pop(),
            child: Material(
              color: Colors.transparent,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                child: Center(
                  child: GestureDetector(
                    onTap:
                        () {}, // prevent taps from closing when tapping content
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: MediaQuery.of(ctx).size.width * 0.95,
                        color: Theme.of(ctx).dialogBackgroundColor,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Top: title
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      ad.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () => Navigator.of(ctx).pop(),
                                  )
                                ],
                              ),
                            ),

                            // Image
                            if (ad.image != null && ad.image!.isNotEmpty)
                              AspectRatio(
                                aspectRatio: 1,
                                child: Image.network(
                                  ad.image!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image,
                                        size: 48),
                                  ),
                                ),
                              ),

                            // Description
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                ad.description ?? '',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),

                            // Likes / comments row (basic)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.favorite_border),
                                    onPressed: () {
                                      // TODO: wire up like action
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(content: Text('Liked')),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.comment_outlined),
                                    onPressed: () {
                                      // TODO: open comments view
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Comments (not implemented)')),
                                      );
                                    },
                                  ),
                                  const Spacer(),
                                  // counts
                                  Text('${ad.likesCount} likes'),
                                  const SizedBox(width: 8),
                                  Text('${ad.commentsCount} comments'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

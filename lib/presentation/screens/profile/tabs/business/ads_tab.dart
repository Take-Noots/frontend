import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../../data/services/advertisement_service.dart';
import '../../../../../data/models/advertisement_model.dart';
import '../../../../../core/constants/app_constants.dart';

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
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

  // Use an unauthenticated Dio instance for public advertisement fetching
  final dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
  final advertisementService = AdvertisementService.unauthenticated(dio);
  final result = await advertisementService.fetchAdvertisementsByUser(widget.userId);

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
      return const Center(
        child: CircularProgressIndicator(),
      );
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
            onTap: () {
              // For now, just show a snackbar with ad title
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ad.title)),
              );
            },
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
}

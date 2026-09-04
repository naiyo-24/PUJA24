import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/graphql_service.dart';
import '../../domain/models/banner_model.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(GraphQLService());
});

class HomeRepository {
  final GraphQLService _graphQLService;

  HomeRepository(this._graphQLService);

  Future<List<BannerModel>> getBanners(double lat, double lng) async {
    const String query = '''
      query GetHomeFeed(\$lat: Float!, \$lng: Float!) {
        homeFeed(lat: \$lat, lng: \$lng) {
          banners {
            id
            title
            subtitle
            bannerType
            imageUrl
            actionType
            actionPayload
          }
        }
      }
    ''';

    final variables = {
      'lat': lat,
      'lng': lng,
    };

    try {
      final response = await _graphQLService.query(query, variables: variables);
      if (response['homeFeed'] != null && response['homeFeed']['banners'] != null) {
        final List<dynamic> data = response['homeFeed']['banners'];
        return data.map((json) => BannerModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('HomeFeed GraphQL Error: \$e');
      return [];
    }
  }
}

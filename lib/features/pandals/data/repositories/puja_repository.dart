import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/puja_detail_model.dart';
import '../../../../core/network/graphql_service.dart';

// Provides the repository instance
final pujaRepositoryProvider = Provider<PujaRepository>((ref) {
  return PujaRepository(GraphQLService());
});

class PujaRepository {
  final GraphQLService _graphQLService;

  PujaRepository(this._graphQLService);

  /// Fetches a list of Pandals using GraphQL
  Future<List<PujaDetailModel>> getPandals({String? area, bool? isPopular, double? lat, double? lng}) async {
    const String query = '''
      query GetPandals(\$area: String, \$isPopular: Boolean, \$lat: Float, \$lng: Float) {
        pandals(area: \$area, isPopular: \$isPopular, lat: \$lat, lng: \$lng) {
          id
          name
          area
          rating
          distance
          latitude
          longitude
          imageUrl
          theme2026
          crowdStatus
          queueTimeMins
          placeMetadata
        }
      }
    ''';

    final variables = {
      if (area != null) 'area': area,
      if (isPopular != null) 'isPopular': isPopular,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    };

    final response = await _graphQLService.query(query, variables: variables);
    
    if (response['pandals'] != null) {
      final List<dynamic> data = response['pandals'];
      return data.map((json) => PujaDetailModel.fromJson(json)).toList();
    }
    
    return [];
  }

  /// Fetches Puja details using GraphQL.
  Future<PujaDetailModel> getPujaDetails(String id) async {
    const String query = '''
      query GetPlaceDetails(\$id: String!) {
        placeDetails(placeId: \$id) {
          id
          name
          area
          rating
          distance
          latitude
          longitude
          imageUrl
          theme2026
          crowdStatus
          queueTimeMins
          placeMetadata
        }
      }
    ''';

    final response = await _graphQLService.query(query, variables: {'id': id});
    
    if (response['placeDetails'] != null) {
      return PujaDetailModel.fromJson(response['placeDetails']);
    } else {
      throw Exception('Pandal not found');
    }
  }

  /// Toggles the saved status of a Pandal
  Future<bool> toggleSavedPandal(String placeId) async {
    const String mutation = '''
      mutation ToggleSavedPlace(\$placeId: String!) {
        toggleSavedPlace(placeId: \$placeId) {
          status
        }
      }
    ''';

    try {
      final response = await _graphQLService.query(mutation, variables: {'placeId': placeId});
      if (response['toggleSavedPlace'] != null) {
        return response['toggleSavedPlace']['status'] == 'saved';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Submits a live update for Rain and Crowd status
  Future<bool> submitLiveUpdate(String placeId, String rainStatus, String crowdStatus) async {
    // TODO: Replace with the actual GraphQL mutation when the backend is ready
    const String mutation = '''
      mutation SubmitLiveUpdate(\$placeId: String!, \$rainStatus: String!, \$crowdStatus: String!) {
        submitLiveUpdate(placeId: \$placeId, rainStatus: \$rainStatus, crowdStatus: \$crowdStatus) {
          success
        }
      }
    ''';

    try {
      final response = await _graphQLService.query(mutation, variables: {
        'placeId': placeId,
        'rainStatus': rainStatus,
        'crowdStatus': crowdStatus,
      });
      
      if (response['submitLiveUpdate'] != null) {
        return response['submitLiveUpdate']['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

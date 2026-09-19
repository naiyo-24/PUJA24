import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/graphql_service.dart';

final allPandalsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final graphqlService = GraphQLService();
  
  const query = '''
    query {
      pandals {
        id
        name
        area
        latitude
        longitude
        imageUrl
      }
    }
  ''';
  
  final response = await graphqlService.query(query);
  final pandalsList = (response['pandals'] as List).cast<Map<String, dynamic>>();
  
  // Sort alphabetically by name
  pandalsList.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
  
  return pandalsList;
});

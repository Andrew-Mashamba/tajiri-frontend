import '../models/location_models.dart';
import 'graphql/graphql_onboarding_service.dart';

/// Location lookups for onboarding — GraphQL only (ref_locations on the backend).
class LocationService {
  final String baseUrl; // retained for call-site compatibility; unused.

  LocationService({this.baseUrl = ''});

  Future<List<Region>> getRegions() async {
    final rows = await GraphqlOnboardingService.regions();
    return rows
        .map((r) => Region(
              id: int.parse('${r['id']}'),
              name: r['name'] as String,
              postCode: r['postCode'] as String?,
            ))
        .toList();
  }

  Future<List<District>> getDistricts(int regionId) async {
    final rows = await GraphqlOnboardingService.locationChildren('$regionId');
    return rows
        .map((r) => District(
              id: int.parse('${r['id']}'),
              regionId: regionId,
              name: r['name'] as String,
              postCode: r['postCode'] as String?,
            ))
        .toList();
  }

  Future<List<Ward>> getWards(int districtId) async {
    final rows = await GraphqlOnboardingService.locationChildren('$districtId');
    return rows
        .map((r) => Ward(
              id: int.parse('${r['id']}'),
              districtId: districtId,
              name: r['name'] as String,
              postCode: r['postCode'] as String?,
            ))
        .toList();
  }

  Future<List<Street>> getStreets(int wardId) async {
    // Streets are embedded on the ward (locationChildren), not a separate query;
    // street selection is optional during onboarding.
    return <Street>[];
  }
}

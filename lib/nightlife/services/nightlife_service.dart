// lib/nightlife/services/nightlife_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/nightlife_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class NightlifeService {
  static Future<PaginatedResult<Venue>> getVenues({
    int page = 1,
    String? type,
    String? search,
  }) async {
    try {
      final q = <String, dynamic>{'page': page};
      if (type != null) q['type'] = type;
      if (search != null) q['search'] = search;
      final r = await _dio.get('/nightlife/venues', queryParameters: q);
      final data = r.data;
      if (data['success'] == true) {
        final items =
            (data['data'] as List).map((j) => Venue.fromJson(j)).toList();
        return PaginatedResult(
          success: true,
          items: items,
          currentPage: data['meta']?['current_page'] ?? page,
          lastPage: data['meta']?['last_page'] ?? 1,
        );
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<NightlifeEvent>> getTonightsEvents() async {
    try {
      final r = await _dio.get('/nightlife/events/tonight');
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => NightlifeEvent.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<NightlifeEvent>> getVenueEvents(
      int venueId) async {
    try {
      final r = await _dio.get('/nightlife/venues/$venueId/events');
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => NightlifeEvent.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<TableReservation>> reserveTable(
      Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/nightlife/reservations', data: body);
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: TableReservation.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<TableReservation>> getMyReservations() async {
    try {
      final r = await _dio.get('/nightlife/reservations');
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => TableReservation.fromJson(j))
            .toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }
}

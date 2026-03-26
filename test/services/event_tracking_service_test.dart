import 'package:flutter_test/flutter_test.dart';
import 'package:tajiri/models/flywheel_models.dart';
import 'package:tajiri/services/event_tracking_service.dart';

void main() {
  group('EventTrackingService', () {
    late EventTrackingService service;

    setUp(() {
      service = EventTrackingService.createForTesting();
    });

    tearDown(() {
      service.dispose();
    });

    test('trackEvent adds event to buffer', () {
      service.trackEvent(
        eventType: 'view',
        postId: 42,
        creatorId: 15,
      );
      expect(service.bufferSize, 1);
    });

    test('trackEvent adds multiple events', () {
      for (int i = 0; i < 5; i++) {
        service.trackEvent(eventType: 'view', postId: i);
      }
      expect(service.bufferSize, 5);
    });

    test('drainBuffer returns and clears events up to max batch', () {
      for (int i = 0; i < 5; i++) {
        service.trackEvent(eventType: 'view', postId: i);
      }
      final drained = service.drainBuffer(maxBatch: 3);
      expect(drained.length, 3);
      expect(service.bufferSize, 2);
    });

    test('drainBuffer returns empty list when buffer is empty', () {
      final drained = service.drainBuffer(maxBatch: 100);
      expect(drained, isEmpty);
    });

    test('session ID is consistent within a service instance', () {
      service.trackEvent(eventType: 'view', postId: 1);
      service.trackEvent(eventType: 'like', postId: 2);
      final events = service.drainBuffer(maxBatch: 10);
      expect(events[0].sessionId, events[1].sessionId);
      expect(events[0].sessionId, isNotEmpty);
    });

    test('events older than 24h are discarded on drain', () {
      final oldEvent = UserEvent(
        eventType: 'view',
        postId: 1,
        timestamp: DateTime.now().subtract(const Duration(hours: 25)),
        sessionId: service.sessionId,
      );
      service.addEventDirectly(oldEvent);
      service.trackEvent(eventType: 'view', postId: 2);

      final events = service.drainBuffer(maxBatch: 100);
      expect(events.length, 1);
      expect(events[0].postId, 2);
    });
  });
}

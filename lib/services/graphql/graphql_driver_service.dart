import '../../shop/delivery/models/tajiri_delivery_models.dart';
import 'graphql_driver_mapper.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL TAJIRI delivery driver app (Phase 19).
class GraphqlDriverService {
  static const _locationFields = r'''
    name
    phone
    address
    lat
    lng
  ''';

  static const _driverFields = r'''
    name
    phone
    vehicleType
    vehiclePlate
    lat
    lng
    rating
  ''';

  static const _jobFields = '''
    id
    jobNumber
    status
    driverId
    pickup {
      $_locationFields
    }
    dropoff {
      $_locationFields
    }
    quotedPriceTzs
    weightKg
    itemValueTzs
    notes
    driver {
      $_driverFields
    }
    paymentMethod
    orderTotalTzs
    codCashCollected
    createdAt
    updatedAt
  ''';

  static const _availableJobsQuery = '''
    query TajiriDeliveryAvailableJobs {
      tajiriDeliveryAvailableJobs {
        $_jobFields
      }
    }
  ''';

  static const _activeJobQuery = '''
    query TajiriDeliveryActiveJob {
      tajiriDeliveryActiveJob {
        $_jobFields
      }
    }
  ''';

  static const _jobStatusQuery = '''
    query TajiriDeliveryJobStatus(\$jobId: ID!) {
      tajiriDeliveryJobStatus(jobId: \$jobId) {
        $_jobFields
      }
    }
  ''';

  static const _earningsQuery = '''
    query TajiriDeliveryDriverEarnings {
      tajiriDeliveryDriverEarnings {
        total
        today
        week
        month
        recentJobs {
          $_jobFields
        }
      }
    }
  ''';

  static Future<bool> goOnline() async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        r'mutation { tajiriDeliveryDriverOnline }',
        auth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> goOffline() async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        r'mutation { tajiriDeliveryDriverOffline }',
        auth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> updateLocation(
    double lat,
    double lng,
    double heading,
  ) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation TajiriDeliveryDriverLocation(\$lat: Float!, \$lng: Float!, \$heading: Float!) {
          tajiriDeliveryDriverLocation(lat: \$lat, lng: \$lng, heading: \$heading)
        }
        ''',
        variables: {'lat': lat, 'lng': lng, 'heading': heading},
        auth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<TajiriDeliveryJob>> getAvailableJobs() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(_availableJobsQuery);
      final raw = data['tajiriDeliveryAvailableJobs'] as List? ?? [];
      return raw
          .map((j) => GraphqlDriverMapper.jobFromGraphql(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<TajiriDeliveryJob?> acceptJob(int jobId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation TajiriDeliveryAcceptJob(\$jobId: ID!) {
          tajiriDeliveryAcceptJob(jobId: \$jobId) {
            $_jobFields
          }
        }
        ''',
        variables: {'jobId': jobId.toString()},
        auth: true,
      );
      final job = data['tajiriDeliveryAcceptJob'] as Map<String, dynamic>?;
      if (job == null) return null;
      return GraphqlDriverMapper.jobFromGraphql(job);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> confirmPickup(int jobId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation TajiriDeliveryConfirmPickup(\$jobId: ID!) {
          tajiriDeliveryConfirmPickup(jobId: \$jobId)
        }
        ''',
        variables: {'jobId': jobId.toString()},
        auth: true,
      );
      return data['tajiriDeliveryConfirmPickup'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> confirmDelivery(int jobId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation TajiriDeliveryConfirmDelivery(\$jobId: ID!) {
          tajiriDeliveryConfirmDelivery(jobId: \$jobId)
        }
        ''',
        variables: {'jobId': jobId.toString()},
        auth: true,
      );
      return data['tajiriDeliveryConfirmDelivery'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> cancelJob(int jobId, String reason) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation TajiriDeliveryCancelJob(\$jobId: ID!, \$reason: String!) {
          tajiriDeliveryCancelJob(jobId: \$jobId, reason: \$reason)
        }
        ''',
        variables: {'jobId': jobId.toString(), 'reason': reason},
        auth: true,
      );
      return data['tajiriDeliveryCancelJob'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<TajiriDeliveryJob?> getActiveJob() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(_activeJobQuery);
      final job = data['tajiriDeliveryActiveJob'] as Map<String, dynamic>?;
      if (job == null) return null;
      return GraphqlDriverMapper.jobFromGraphql(job);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> collectCashPayment(int jobId, double amount) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation TajiriDeliveryCollectCash(\$jobId: ID!, \$amount: Float!) {
          tajiriDeliveryCollectCash(jobId: \$jobId, amount: \$amount)
        }
        ''',
        variables: {'jobId': jobId.toString(), 'amount': amount},
        auth: true,
      );
      return data['tajiriDeliveryCollectCash'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> getEarnings() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(_earningsQuery);
      final earnings = data['tajiriDeliveryDriverEarnings'] as Map<String, dynamic>?;
      if (earnings == null) return {};
      return GraphqlDriverMapper.earningsToLegacy(earnings);
    } catch (_) {
      return {};
    }
  }

  static Future<TajiriDeliveryJob?> getJobStatus(int jobId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        _jobStatusQuery,
        variables: {'jobId': jobId.toString()},
      );
      final job = data['tajiriDeliveryJobStatus'] as Map<String, dynamic>?;
      if (job == null) return null;
      return GraphqlDriverMapper.jobFromGraphql(job);
    } catch (_) {
      return null;
    }
  }
}

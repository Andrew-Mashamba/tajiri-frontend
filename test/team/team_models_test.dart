// test/team/team_models_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tajiri/team/models/team_models.dart';

void main() {
  group('Allowance', () {
    test('fromJson parses name and amount', () {
      final a = Allowance.fromJson({'name': 'Transport', 'amount': 50000});
      expect(a.name, 'Transport');
      expect(a.amount, 50000.0);
    });
    test('toJson round-trips', () {
      const a = Allowance(name: 'Housing', amount: 100000);
      expect(Allowance.fromJson(a.toJson()).amount, 100000.0);
    });
  });

  group('PlatformUser', () {
    test('fromJson parses id, name, username, avatarUrl', () {
      final u = PlatformUser.fromJson(
          {'id': 7, 'name': 'Alice', 'username': 'alice99', 'profile_photo_url': 'https://x.com/a.jpg'});
      expect(u.id, 7);
      expect(u.username, 'alice99');
      expect(u.avatarUrl, 'https://x.com/a.jpg');
    });
    test('avatarUrl is nullable', () {
      final u = PlatformUser.fromJson({'id': 1, 'name': 'Bob', 'username': 'bob'});
      expect(u.avatarUrl, isNull);
    });
  });

  group('Employee (enhanced)', () {
    final json = {
      'id': 5, 'business_id': 2, 'user_id': 10,
      'name': 'Jane', 'phone': '0712345678', 'position': 'Engineer',
      'department': 'Tech', 'contract_type': 'permanent',
      'gross_salary': 800000, 'apply_paye': true, 'apply_nssf': true, 'apply_nhif': false,
      'allowances': [{'name': 'Transport', 'amount': 30000}],
      'start_date': '2024-01-01', 'bank_account': '123', 'bank_name': 'NBC', 'is_active': true,
    };
    test('fromJson parses all new fields', () {
      final e = Employee.fromJson(json);
      expect(e.userId, 10);
      expect(e.department, 'Tech');
      expect(e.contractType, 'permanent');
      expect(e.applyPAYE, true);
      expect(e.applyNHIF, false);
      expect(e.allowances.length, 1);
      expect(e.allowances.first.name, 'Transport');
    });
    test('toJson includes all new fields', () {
      final j = Employee.fromJson(json).toJson();
      expect(j['user_id'], 10);
      expect(j['department'], 'Tech');
      expect((j['allowances'] as List).length, 1);
    });
  });
}

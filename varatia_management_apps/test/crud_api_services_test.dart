import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:varatia_management_apps/core/config/api_config.dart';
import 'package:varatia_management_apps/core/models/user_role.dart';
import 'package:varatia_management_apps/data/services/auth_session_service.dart';
import 'package:varatia_management_apps/data/services/expense_api_service.dart';
import 'package:varatia_management_apps/data/services/owner_tenant_api_service.dart';
import 'package:varatia_management_apps/data/services/property_management_api_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  setUp(() async {
    await AuthSessionService().clear();
  });

  test(
    'property building, floor and unit support create, update and delete',
    () async {
      if (ApiConfig.isDemoMode) {
        return;
      }

      await AuthSessionService().saveSession(
        AuthSession(
          userId: 'owner-1',
          fullName: 'Owner',
          phoneNumber: '01700000000',
          role: EntryUserRole.owner,
          isPhoneVerified: true,
        ),
      );

      final requests = <String>[];
      final service = PropertyManagementApiService(
        client: MockClient((request) async {
          requests.add('${request.method} ${request.url.path}');
          final body = request.body.isEmpty
              ? const <String, dynamic>{}
              : jsonDecode(request.body) as Map<String, dynamic>;

          if (request.url.path.endsWith('/buildings') &&
              request.method == 'POST') {
            expect(body['user_id'], 'owner-1');
            return _jsonResponse({
              'building': {
                'id': 'B-10',
                'name': body['name'],
                'location': body['location'],
                'totalFloors': body['totalFloors'],
              },
            }, 201);
          }
          if (request.url.path.endsWith('/buildings/B-10') &&
              request.method == 'PUT') {
            expect(body['user_id'], 'owner-1');
            return _jsonResponse({
              'building': {
                'id': 'B-10',
                'name': body['name'],
                'location': body['location'],
                'totalFloors': body['totalFloors'],
              },
            });
          }
          if (request.url.path.endsWith('/buildings/B-10')) {
            return _jsonResponse({'buildingId': 'B-10'});
          }
          if (request.url.path.endsWith('/floors') &&
              request.method == 'POST') {
            return _jsonResponse({
              'floor': {'id': 'F-10', ...body},
            }, 201);
          }
          if (request.url.path.endsWith('/floors/F-10') &&
              request.method == 'PUT') {
            return _jsonResponse({
              'floor': {'id': 'F-10', ...body},
            });
          }
          if (request.url.path.endsWith('/floors/F-10')) {
            return _jsonResponse({'floorId': 'F-10', 'buildingId': 'B-10'});
          }
          if (request.url.path.endsWith('/units') && request.method == 'POST') {
            return _jsonResponse({
              'property': _propertyPayload('P-10', body),
            }, 201);
          }
          if (request.url.path.endsWith('/units/P-10') &&
              request.method == 'PUT') {
            return _jsonResponse({'property': _propertyPayload('P-10', body)});
          }
          if (request.url.path.endsWith('/units/P-10')) {
            return _jsonResponse({'propertyId': 'P-10'});
          }
          return _jsonResponse({'message': 'Unexpected request'}, 500);
        }),
      );

      final building = await service.createBuilding(
        name: 'Tower A',
        location: 'Dhaka',
        totalFloors: 5,
      );
      final updatedBuilding = await service.updateBuilding(
        buildingId: building.building.id,
        name: 'Tower A+',
        location: 'Dhaka',
        totalFloors: 6,
      );
      final floor = await service.createFloor(
        buildingId: building.building.id,
        label: 'Floor 1',
        totalUnits: 2,
      );
      final updatedFloor = await service.updateFloor(
        floorId: floor.floor.id,
        buildingId: building.building.id,
        label: 'Ground Floor',
        totalUnits: 3,
      );
      final unit = await service.createUnit(
        name: 'A-1',
        monthlyRent: 12000,
        buildingId: building.building.id,
        floorId: floor.floor.id,
      );
      final updatedUnit = await service.updateUnit(
        propertyId: unit.property.id,
        name: 'A-1 Updated',
        monthlyRent: 13000,
        buildingId: building.building.id,
        floorId: floor.floor.id,
      );

      expect(updatedBuilding.building.name, 'Tower A+');
      expect(updatedFloor.floor.label, 'Ground Floor');
      expect(updatedUnit.property.monthlyRent, 13000);
      expect((await service.deleteUnit(propertyId: 'P-10')).propertyId, 'P-10');
      expect((await service.deleteFloor(floorId: 'F-10')).floorId, 'F-10');
      expect(
        (await service.deleteBuilding(buildingId: 'B-10')).buildingId,
        'B-10',
      );
      expect(requests, hasLength(9));
    },
  );

  test('expense supports entry, edit and delete', () async {
    if (ApiConfig.isDemoMode) return;
    final service = ExpenseApiService(
      client: MockClient((request) async {
        final body = request.body.isEmpty
            ? null
            : jsonDecode(request.body) as Map<String, dynamic>;
        if (request.method == 'POST') {
          return _jsonResponse({
            'expense': {'id': 7, ...body!},
          }, 201);
        }
        if (request.method == 'PUT') {
          return _jsonResponse({
            'expense': {'id': 7, ...body!},
          });
        }
        return _jsonResponse({'expenseId': 7});
      }),
    );

    final created = await service.createExpense(
      title: 'Electricity',
      category: 'Utility',
      amount: 2000,
      monthLabel: 'July 2026',
      userId: 'owner-1',
    );
    final updated = await service.updateExpense(
      expenseId: created.expense.id,
      title: 'Electricity Bill',
      category: 'Utility',
      amount: 2200,
      monthLabel: 'July 2026',
      userId: 'owner-1',
    );
    final deleted = await service.deleteExpense(expenseId: updated.expense.id);

    expect(created.expense.title, 'Electricity');
    expect(updated.expense.amount, 2200);
    expect(deleted.expenseId, 7);
  });

  test('tenant supports entry, edit, move-out and delete', () async {
    if (ApiConfig.isDemoMode) return;
    final service = OwnerTenantApiService(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/move-out')) {
          return _jsonResponse({
            'tenant': _tenantPayload(propertyName: 'Moved out'),
            'previousPropertyId': 'P-1',
            'previousPropertyName': 'A-1',
          });
        }
        if (request.method == 'DELETE') {
          return _jsonResponse({
            'tenantId': 'T-1',
            'propertyId': 'P-1',
            'propertyName': 'A-1',
          });
        }
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final payload = {
          'tenant': _tenantPayload(
            name: body['fullName'] as String?,
            phone: body['phoneNumber'] as String?,
            nid: body['nid'] as String?,
          ),
          'propertyId': 'P-1',
          'propertyName': 'A-1',
        };
        if (request.method == 'POST') {
          payload.addAll({
            'loginPhoneNumber': body['phoneNumber'],
            'temporaryPassword': '123456',
          });
        }
        return _jsonResponse(payload, request.method == 'POST' ? 201 : 200);
      }),
    );

    final created = await service.createTenant(
      fullName: 'Rahim',
      phoneNumber: '01711111111',
      nid: '1234',
      propertyId: 'P-1',
    );
    final updated = await service.updateTenant(
      tenantId: created.tenant.id,
      fullName: 'Rahim Uddin',
      phoneNumber: '01711111111',
      nid: '5678',
    );
    final moved = await service.moveOutTenant(tenantId: updated.tenant.id);
    final deleted = await service.deleteTenant(tenantId: updated.tenant.id);

    expect(created.temporaryPassword, '123456');
    expect(updated.tenant.name, 'Rahim Uddin');
    expect(moved.previousPropertyId, 'P-1');
    expect(deleted.tenantId, 'T-1');
  });
}

http.Response _jsonResponse(Object body, [int statusCode = 200]) =>
    http.Response(
      jsonEncode(body),
      statusCode,
      headers: const {'content-type': 'application/json'},
    );

Map<String, dynamic> _propertyPayload(String id, Map<String, dynamic> body) => {
  'id': id,
  'name': body['name'],
  'location': 'Dhaka',
  'monthlyRent': body['monthlyRent'],
  'status': 'available',
  'buildingId': body['buildingId'],
  'floorId': body['floorId'],
};

Map<String, dynamic> _tenantPayload({
  String? name,
  String? phone,
  String? nid,
  String propertyName = 'A-1',
}) => {
  'id': 'T-1',
  'name': name ?? 'Rahim',
  'phone': phone ?? '01711111111',
  'nid': nid ?? '1234',
  'propertyName': propertyName,
  'propertyId': 'P-1',
};

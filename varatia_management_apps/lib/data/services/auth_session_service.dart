import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../../core/models/user_role.dart';

class AuthSessionService {
  static const String _databaseName = 'varatia_auth_session.db';
  static const int _databaseVersion = 3;
  static const String _tableName = 'auth_session';
  static const int _sessionRowId = 1;
  static const String _createdAtColumn = 'created_at';
  static const String _lastHomeTabIndexColumn = 'last_home_tab_index';

  static Database? _database;
  static AuthSession? _cachedSession;
  static Future<AuthSession?>? _sessionReadFuture;
  static bool _hasCachedSession = false;

  Future<void> saveSession(AuthSession session) async {
    final normalizedUserId = session.userId.trim();
    if (normalizedUserId.isEmpty) {
      return;
    }

    final normalizedSession = AuthSession(
      userId: normalizedUserId,
      fullName: session.fullName.trim(),
      phoneNumber: session.phoneNumber.trim(),
      role: session.role,
      isPhoneVerified: session.isPhoneVerified,
      createdAt: session.createdAt,
      lastHomeTabIndex: session.lastHomeTabIndex,
      savedAt: session.savedAt,
    );
    final database = await _openDatabase();
    await database.insert(_tableName, {
      'id': _sessionRowId,
      'user_id': normalizedSession.userId,
      'full_name': normalizedSession.fullName,
      'phone_number': normalizedSession.phoneNumber,
      'role': normalizedSession.role?.apiValue,
      'is_phone_verified': normalizedSession.isPhoneVerified ? 1 : 0,
      _createdAtColumn: normalizedSession.createdAt?.toUtc().toIso8601String(),
      _lastHomeTabIndexColumn: normalizedSession.lastHomeTabIndex,
      'saved_at': normalizedSession.savedAt.toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    _cacheSession(normalizedSession);
  }

  Future<void> saveUserId(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return;
    }

    final existingSession = await readSession();
    await saveSession(
      AuthSession(
        userId: normalizedUserId,
        fullName: existingSession?.fullName ?? '',
        phoneNumber: existingSession?.phoneNumber ?? '',
        role: existingSession?.role,
        isPhoneVerified: existingSession?.isPhoneVerified ?? false,
        createdAt: existingSession?.createdAt,
      ),
    );
  }

  Future<void> saveRole(EntryUserRole role) async {
    final existingSession = await readSession();
    if (existingSession == null) {
      return;
    }

    await saveSession(existingSession.copyWith(role: role));
  }

  Future<void> saveLastHomeTabIndex(int tabIndex) async {
    final existingSession = await readSession();
    if (existingSession == null) {
      return;
    }

    await saveSession(existingSession.copyWith(lastHomeTabIndex: tabIndex));
  }

  Future<AuthSession?> readSession({bool forceRefresh = false}) async {
    if (!forceRefresh && _hasCachedSession) {
      return _cachedSession;
    }

    final pendingRead = _sessionReadFuture;
    if (!forceRefresh && pendingRead != null) {
      return pendingRead;
    }

    final readFuture = _readSessionFromDatabase();
    _sessionReadFuture = readFuture;

    try {
      final session = await readFuture;
      _cacheSession(session);
      return session;
    } finally {
      if (identical(_sessionReadFuture, readFuture)) {
        _sessionReadFuture = null;
      }
    }
  }

  Future<AuthSession?> _readSessionFromDatabase() async {
    final database = await _openDatabase();
    final rows = await database.query(
      _tableName,
      where: 'id = ?',
      whereArgs: const [_sessionRowId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return AuthSession.fromMap(rows.first);
  }

  Future<String?> readUserId() async {
    final session = await readSession();
    final userId = session?.userId.trim();
    return userId == null || userId.isEmpty ? null : userId;
  }

  Future<void> clear() async {
    final database = await _openDatabase();
    await database.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: const [_sessionRowId],
    );
    _cacheSession(null);
  }

  static void _cacheSession(AuthSession? session) {
    _cachedSession = session;
    _hasCachedSession = true;
  }

  Future<Database> _openDatabase() async {
    final cachedDatabase = _database;
    if (cachedDatabase != null) {
      return cachedDatabase;
    }

    final databaseDirectory = await getDatabasesPath();
    final databasePath = path.join(databaseDirectory, _databaseName);
    final database = await openDatabase(
      databasePath,
      version: _databaseVersion,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY CHECK (id = $_sessionRowId),
            user_id TEXT NOT NULL,
            full_name TEXT NOT NULL DEFAULT '',
            phone_number TEXT NOT NULL DEFAULT '',
            role TEXT NULL,
            is_phone_verified INTEGER NOT NULL DEFAULT 0,
            $_createdAtColumn TEXT NULL,
            $_lastHomeTabIndexColumn INTEGER NOT NULL DEFAULT 0,
            saved_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (database, oldVersion, version) async {
        if (oldVersion < 2) {
          await _ensureLastHomeTabIndexColumn(database);
        }
        if (oldVersion < 3) {
          await _ensureCreatedAtColumn(database);
        }
      },
    );

    _database = database;
    return database;
  }

  Future<void> _ensureLastHomeTabIndexColumn(Database database) async {
    final columns = await database.rawQuery('PRAGMA table_info($_tableName)');
    final hasColumn = columns.any(
      (column) => column['name'] == _lastHomeTabIndexColumn,
    );

    if (hasColumn) {
      return;
    }

    await database.execute(
      'ALTER TABLE $_tableName ADD COLUMN '
      '$_lastHomeTabIndexColumn INTEGER NOT NULL DEFAULT 0',
    );
  }

  Future<void> _ensureCreatedAtColumn(Database database) async {
    final columns = await database.rawQuery('PRAGMA table_info($_tableName)');
    final hasColumn = columns.any(
      (column) => column['name'] == _createdAtColumn,
    );

    if (hasColumn) {
      return;
    }

    await database.execute(
      'ALTER TABLE $_tableName ADD COLUMN $_createdAtColumn TEXT NULL',
    );
  }
}

class AuthSession {
  AuthSession({
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    required this.isPhoneVerified,
    this.createdAt,
    int lastHomeTabIndex = 0,
    DateTime? savedAt,
  }) : lastHomeTabIndex = lastHomeTabIndex < 0 ? 0 : lastHomeTabIndex,
       savedAt = savedAt ?? DateTime.now().toUtc();

  final String userId;
  final String fullName;
  final String phoneNumber;
  final EntryUserRole? role;
  final bool isPhoneVerified;
  final DateTime? createdAt;
  final int lastHomeTabIndex;
  final DateTime savedAt;

  factory AuthSession.fromMap(Map<String, Object?> map) {
    final createdAtValue = map['created_at'];
    final savedAtValue = map['saved_at'];

    return AuthSession(
      userId: map['user_id'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      phoneNumber: map['phone_number'] as String? ?? '',
      role: entryUserRoleFromApiValue(map['role'] as String?),
      isPhoneVerified: (map['is_phone_verified'] as int? ?? 0) == 1,
      createdAt: createdAtValue is String
          ? DateTime.tryParse(createdAtValue)?.toUtc()
          : null,
      lastHomeTabIndex: map['last_home_tab_index'] as int? ?? 0,
      savedAt: savedAtValue is String
          ? DateTime.tryParse(savedAtValue)?.toUtc()
          : null,
    );
  }

  AuthSession copyWith({
    String? userId,
    String? fullName,
    String? phoneNumber,
    EntryUserRole? role,
    bool? isPhoneVerified,
    DateTime? createdAt,
    int? lastHomeTabIndex,
    DateTime? savedAt,
  }) {
    return AuthSession(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      createdAt: createdAt ?? this.createdAt,
      lastHomeTabIndex: lastHomeTabIndex ?? this.lastHomeTabIndex,
      savedAt: savedAt ?? DateTime.now().toUtc(),
    );
  }
}

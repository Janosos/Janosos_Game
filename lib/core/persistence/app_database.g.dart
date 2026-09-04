// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UserNamespacesTable extends UserNamespaces
    with TableInfo<$UserNamespacesTable, UserNamespace> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserNamespacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _protectedScopeMeta = const VerificationMeta(
    'protectedScope',
  );
  @override
  late final GeneratedColumn<String> protectedScope = GeneratedColumn<String>(
    'protected_scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _protectedStorageAvailableMeta =
      const VerificationMeta('protectedStorageAvailable');
  @override
  late final GeneratedColumn<bool> protectedStorageAvailable =
      GeneratedColumn<bool>(
        'protected_storage_available',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("protected_storage_available" IN (0, 1))',
        ),
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastActivatedAtMeta = const VerificationMeta(
    'lastActivatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastActivatedAt =
      GeneratedColumn<DateTime>(
        'last_activated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    protectedScope,
    protectedStorageAvailable,
    createdAt,
    lastActivatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_namespaces';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserNamespace> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('protected_scope')) {
      context.handle(
        _protectedScopeMeta,
        protectedScope.isAcceptableOrUnknown(
          data['protected_scope']!,
          _protectedScopeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_protectedScopeMeta);
    }
    if (data.containsKey('protected_storage_available')) {
      context.handle(
        _protectedStorageAvailableMeta,
        protectedStorageAvailable.isAcceptableOrUnknown(
          data['protected_storage_available']!,
          _protectedStorageAvailableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_protectedStorageAvailableMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_activated_at')) {
      context.handle(
        _lastActivatedAtMeta,
        lastActivatedAt.isAcceptableOrUnknown(
          data['last_activated_at']!,
          _lastActivatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastActivatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  UserNamespace map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserNamespace(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      protectedScope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}protected_scope'],
      )!,
      protectedStorageAvailable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}protected_storage_available'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastActivatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_activated_at'],
      )!,
    );
  }

  @override
  $UserNamespacesTable createAlias(String alias) {
    return $UserNamespacesTable(attachedDatabase, alias);
  }
}

class UserNamespace extends DataClass implements Insertable<UserNamespace> {
  final String userId;
  final String protectedScope;
  final bool protectedStorageAvailable;
  final DateTime createdAt;
  final DateTime lastActivatedAt;
  const UserNamespace({
    required this.userId,
    required this.protectedScope,
    required this.protectedStorageAvailable,
    required this.createdAt,
    required this.lastActivatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['protected_scope'] = Variable<String>(protectedScope);
    map['protected_storage_available'] = Variable<bool>(
      protectedStorageAvailable,
    );
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_activated_at'] = Variable<DateTime>(lastActivatedAt);
    return map;
  }

  UserNamespacesCompanion toCompanion(bool nullToAbsent) {
    return UserNamespacesCompanion(
      userId: Value(userId),
      protectedScope: Value(protectedScope),
      protectedStorageAvailable: Value(protectedStorageAvailable),
      createdAt: Value(createdAt),
      lastActivatedAt: Value(lastActivatedAt),
    );
  }

  factory UserNamespace.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserNamespace(
      userId: serializer.fromJson<String>(json['userId']),
      protectedScope: serializer.fromJson<String>(json['protectedScope']),
      protectedStorageAvailable: serializer.fromJson<bool>(
        json['protectedStorageAvailable'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastActivatedAt: serializer.fromJson<DateTime>(json['lastActivatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'protectedScope': serializer.toJson<String>(protectedScope),
      'protectedStorageAvailable': serializer.toJson<bool>(
        protectedStorageAvailable,
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastActivatedAt': serializer.toJson<DateTime>(lastActivatedAt),
    };
  }

  UserNamespace copyWith({
    String? userId,
    String? protectedScope,
    bool? protectedStorageAvailable,
    DateTime? createdAt,
    DateTime? lastActivatedAt,
  }) => UserNamespace(
    userId: userId ?? this.userId,
    protectedScope: protectedScope ?? this.protectedScope,
    protectedStorageAvailable:
        protectedStorageAvailable ?? this.protectedStorageAvailable,
    createdAt: createdAt ?? this.createdAt,
    lastActivatedAt: lastActivatedAt ?? this.lastActivatedAt,
  );
  UserNamespace copyWithCompanion(UserNamespacesCompanion data) {
    return UserNamespace(
      userId: data.userId.present ? data.userId.value : this.userId,
      protectedScope: data.protectedScope.present
          ? data.protectedScope.value
          : this.protectedScope,
      protectedStorageAvailable: data.protectedStorageAvailable.present
          ? data.protectedStorageAvailable.value
          : this.protectedStorageAvailable,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastActivatedAt: data.lastActivatedAt.present
          ? data.lastActivatedAt.value
          : this.lastActivatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserNamespace(')
          ..write('userId: $userId, ')
          ..write('protectedScope: $protectedScope, ')
          ..write('protectedStorageAvailable: $protectedStorageAvailable, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastActivatedAt: $lastActivatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    protectedScope,
    protectedStorageAvailable,
    createdAt,
    lastActivatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserNamespace &&
          other.userId == this.userId &&
          other.protectedScope == this.protectedScope &&
          other.protectedStorageAvailable == this.protectedStorageAvailable &&
          other.createdAt == this.createdAt &&
          other.lastActivatedAt == this.lastActivatedAt);
}

class UserNamespacesCompanion extends UpdateCompanion<UserNamespace> {
  final Value<String> userId;
  final Value<String> protectedScope;
  final Value<bool> protectedStorageAvailable;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastActivatedAt;
  final Value<int> rowid;
  const UserNamespacesCompanion({
    this.userId = const Value.absent(),
    this.protectedScope = const Value.absent(),
    this.protectedStorageAvailable = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastActivatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserNamespacesCompanion.insert({
    required String userId,
    required String protectedScope,
    required bool protectedStorageAvailable,
    required DateTime createdAt,
    required DateTime lastActivatedAt,
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       protectedScope = Value(protectedScope),
       protectedStorageAvailable = Value(protectedStorageAvailable),
       createdAt = Value(createdAt),
       lastActivatedAt = Value(lastActivatedAt);
  static Insertable<UserNamespace> custom({
    Expression<String>? userId,
    Expression<String>? protectedScope,
    Expression<bool>? protectedStorageAvailable,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastActivatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (protectedScope != null) 'protected_scope': protectedScope,
      if (protectedStorageAvailable != null)
        'protected_storage_available': protectedStorageAvailable,
      if (createdAt != null) 'created_at': createdAt,
      if (lastActivatedAt != null) 'last_activated_at': lastActivatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserNamespacesCompanion copyWith({
    Value<String>? userId,
    Value<String>? protectedScope,
    Value<bool>? protectedStorageAvailable,
    Value<DateTime>? createdAt,
    Value<DateTime>? lastActivatedAt,
    Value<int>? rowid,
  }) {
    return UserNamespacesCompanion(
      userId: userId ?? this.userId,
      protectedScope: protectedScope ?? this.protectedScope,
      protectedStorageAvailable:
          protectedStorageAvailable ?? this.protectedStorageAvailable,
      createdAt: createdAt ?? this.createdAt,
      lastActivatedAt: lastActivatedAt ?? this.lastActivatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (protectedScope.present) {
      map['protected_scope'] = Variable<String>(protectedScope.value);
    }
    if (protectedStorageAvailable.present) {
      map['protected_storage_available'] = Variable<bool>(
        protectedStorageAvailable.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastActivatedAt.present) {
      map['last_activated_at'] = Variable<DateTime>(lastActivatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserNamespacesCompanion(')
          ..write('userId: $userId, ')
          ..write('protectedScope: $protectedScope, ')
          ..write('protectedStorageAvailable: $protectedStorageAvailable, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastActivatedAt: $lastActivatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedProfilesTable extends CachedProfiles
    with TableInfo<$CachedProfilesTable, CachedProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailVerifiedMeta = const VerificationMeta(
    'emailVerified',
  );
  @override
  late final GeneratedColumn<bool> emailVerified = GeneratedColumn<bool>(
    'email_verified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("email_verified" IN (0, 1))',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    email,
    displayName,
    emailVerified,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('email_verified')) {
      context.handle(
        _emailVerifiedMeta,
        emailVerified.isAcceptableOrUnknown(
          data['email_verified']!,
          _emailVerifiedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_emailVerifiedMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  CachedProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedProfile(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      emailVerified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}email_verified'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedProfilesTable createAlias(String alias) {
    return $CachedProfilesTable(attachedDatabase, alias);
  }
}

class CachedProfile extends DataClass implements Insertable<CachedProfile> {
  final String userId;
  final String email;
  final String displayName;
  final bool emailVerified;
  final DateTime updatedAt;
  const CachedProfile({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.emailVerified,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['email'] = Variable<String>(email);
    map['display_name'] = Variable<String>(displayName);
    map['email_verified'] = Variable<bool>(emailVerified);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedProfilesCompanion toCompanion(bool nullToAbsent) {
    return CachedProfilesCompanion(
      userId: Value(userId),
      email: Value(email),
      displayName: Value(displayName),
      emailVerified: Value(emailVerified),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedProfile(
      userId: serializer.fromJson<String>(json['userId']),
      email: serializer.fromJson<String>(json['email']),
      displayName: serializer.fromJson<String>(json['displayName']),
      emailVerified: serializer.fromJson<bool>(json['emailVerified']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'email': serializer.toJson<String>(email),
      'displayName': serializer.toJson<String>(displayName),
      'emailVerified': serializer.toJson<bool>(emailVerified),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedProfile copyWith({
    String? userId,
    String? email,
    String? displayName,
    bool? emailVerified,
    DateTime? updatedAt,
  }) => CachedProfile(
    userId: userId ?? this.userId,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    emailVerified: emailVerified ?? this.emailVerified,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedProfile copyWithCompanion(CachedProfilesCompanion data) {
    return CachedProfile(
      userId: data.userId.present ? data.userId.value : this.userId,
      email: data.email.present ? data.email.value : this.email,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      emailVerified: data.emailVerified.present
          ? data.emailVerified.value
          : this.emailVerified,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedProfile(')
          ..write('userId: $userId, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('emailVerified: $emailVerified, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(userId, email, displayName, emailVerified, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedProfile &&
          other.userId == this.userId &&
          other.email == this.email &&
          other.displayName == this.displayName &&
          other.emailVerified == this.emailVerified &&
          other.updatedAt == this.updatedAt);
}

class CachedProfilesCompanion extends UpdateCompanion<CachedProfile> {
  final Value<String> userId;
  final Value<String> email;
  final Value<String> displayName;
  final Value<bool> emailVerified;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CachedProfilesCompanion({
    this.userId = const Value.absent(),
    this.email = const Value.absent(),
    this.displayName = const Value.absent(),
    this.emailVerified = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedProfilesCompanion.insert({
    required String userId,
    required String email,
    required String displayName,
    required bool emailVerified,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       email = Value(email),
       displayName = Value(displayName),
       emailVerified = Value(emailVerified),
       updatedAt = Value(updatedAt);
  static Insertable<CachedProfile> custom({
    Expression<String>? userId,
    Expression<String>? email,
    Expression<String>? displayName,
    Expression<bool>? emailVerified,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (email != null) 'email': email,
      if (displayName != null) 'display_name': displayName,
      if (emailVerified != null) 'email_verified': emailVerified,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedProfilesCompanion copyWith({
    Value<String>? userId,
    Value<String>? email,
    Value<String>? displayName,
    Value<bool>? emailVerified,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CachedProfilesCompanion(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      emailVerified: emailVerified ?? this.emailVerified,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (emailVerified.present) {
      map['email_verified'] = Variable<bool>(emailVerified.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedProfilesCompanion(')
          ..write('userId: $userId, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('emailVerified: $emailVerified, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxItemsTable extends OutboxItems
    with TableInfo<$OutboxItemsTable, OutboxItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commandTypeMeta = const VerificationMeta(
    'commandType',
  );
  @override
  late final GeneratedColumn<String> commandType = GeneratedColumn<String>(
    'command_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectionIdMeta = const VerificationMeta(
    'projectionId',
  );
  @override
  late final GeneratedColumn<String> projectionId = GeneratedColumn<String>(
    'projection_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _encryptedPayloadMeta = const VerificationMeta(
    'encryptedPayload',
  );
  @override
  late final GeneratedColumn<Uint8List> encryptedPayload =
      GeneratedColumn<Uint8List>(
        'encrypted_payload',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _nonceMeta = const VerificationMeta('nonce');
  @override
  late final GeneratedColumn<Uint8List> nonce = GeneratedColumn<Uint8List>(
    'nonce',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _byteSizeMeta = const VerificationMeta(
    'byteSize',
  );
  @override
  late final GeneratedColumn<int> byteSize = GeneratedColumn<int>(
    'byte_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastErrorCodeMeta = const VerificationMeta(
    'lastErrorCode',
  );
  @override
  late final GeneratedColumn<String> lastErrorCode = GeneratedColumn<String>(
    'last_error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    commandType,
    idempotencyKey,
    projectionId,
    encryptedPayload,
    nonce,
    status,
    attemptCount,
    byteSize,
    createdAt,
    nextAttemptAt,
    expiresAt,
    lastErrorCode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('command_type')) {
      context.handle(
        _commandTypeMeta,
        commandType.isAcceptableOrUnknown(
          data['command_type']!,
          _commandTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_commandTypeMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('projection_id')) {
      context.handle(
        _projectionIdMeta,
        projectionId.isAcceptableOrUnknown(
          data['projection_id']!,
          _projectionIdMeta,
        ),
      );
    }
    if (data.containsKey('encrypted_payload')) {
      context.handle(
        _encryptedPayloadMeta,
        encryptedPayload.isAcceptableOrUnknown(
          data['encrypted_payload']!,
          _encryptedPayloadMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedPayloadMeta);
    }
    if (data.containsKey('nonce')) {
      context.handle(
        _nonceMeta,
        nonce.isAcceptableOrUnknown(data['nonce']!, _nonceMeta),
      );
    } else if (isInserting) {
      context.missing(_nonceMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('byte_size')) {
      context.handle(
        _byteSizeMeta,
        byteSize.isAcceptableOrUnknown(data['byte_size']!, _byteSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_byteSizeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextAttemptAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    if (data.containsKey('last_error_code')) {
      context.handle(
        _lastErrorCodeMeta,
        lastErrorCode.isAcceptableOrUnknown(
          data['last_error_code']!,
          _lastErrorCodeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {userId, commandType, idempotencyKey},
  ];
  @override
  OutboxItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      commandType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}command_type'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      projectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}projection_id'],
      ),
      encryptedPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}encrypted_payload'],
      )!,
      nonce: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}nonce'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      byteSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_size'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
      lastErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_code'],
      ),
    );
  }

  @override
  $OutboxItemsTable createAlias(String alias) {
    return $OutboxItemsTable(attachedDatabase, alias);
  }
}

class OutboxItem extends DataClass implements Insertable<OutboxItem> {
  final String id;
  final String userId;
  final String commandType;
  final String idempotencyKey;
  final String? projectionId;
  final Uint8List encryptedPayload;
  final Uint8List nonce;
  final String status;
  final int attemptCount;
  final int byteSize;
  final DateTime createdAt;
  final DateTime nextAttemptAt;
  final DateTime expiresAt;
  final String? lastErrorCode;
  const OutboxItem({
    required this.id,
    required this.userId,
    required this.commandType,
    required this.idempotencyKey,
    this.projectionId,
    required this.encryptedPayload,
    required this.nonce,
    required this.status,
    required this.attemptCount,
    required this.byteSize,
    required this.createdAt,
    required this.nextAttemptAt,
    required this.expiresAt,
    this.lastErrorCode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['command_type'] = Variable<String>(commandType);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    if (!nullToAbsent || projectionId != null) {
      map['projection_id'] = Variable<String>(projectionId);
    }
    map['encrypted_payload'] = Variable<Uint8List>(encryptedPayload);
    map['nonce'] = Variable<Uint8List>(nonce);
    map['status'] = Variable<String>(status);
    map['attempt_count'] = Variable<int>(attemptCount);
    map['byte_size'] = Variable<int>(byteSize);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    if (!nullToAbsent || lastErrorCode != null) {
      map['last_error_code'] = Variable<String>(lastErrorCode);
    }
    return map;
  }

  OutboxItemsCompanion toCompanion(bool nullToAbsent) {
    return OutboxItemsCompanion(
      id: Value(id),
      userId: Value(userId),
      commandType: Value(commandType),
      idempotencyKey: Value(idempotencyKey),
      projectionId: projectionId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectionId),
      encryptedPayload: Value(encryptedPayload),
      nonce: Value(nonce),
      status: Value(status),
      attemptCount: Value(attemptCount),
      byteSize: Value(byteSize),
      createdAt: Value(createdAt),
      nextAttemptAt: Value(nextAttemptAt),
      expiresAt: Value(expiresAt),
      lastErrorCode: lastErrorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorCode),
    );
  }

  factory OutboxItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxItem(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      commandType: serializer.fromJson<String>(json['commandType']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      projectionId: serializer.fromJson<String?>(json['projectionId']),
      encryptedPayload: serializer.fromJson<Uint8List>(
        json['encryptedPayload'],
      ),
      nonce: serializer.fromJson<Uint8List>(json['nonce']),
      status: serializer.fromJson<String>(json['status']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      byteSize: serializer.fromJson<int>(json['byteSize']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      nextAttemptAt: serializer.fromJson<DateTime>(json['nextAttemptAt']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
      lastErrorCode: serializer.fromJson<String?>(json['lastErrorCode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'commandType': serializer.toJson<String>(commandType),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'projectionId': serializer.toJson<String?>(projectionId),
      'encryptedPayload': serializer.toJson<Uint8List>(encryptedPayload),
      'nonce': serializer.toJson<Uint8List>(nonce),
      'status': serializer.toJson<String>(status),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'byteSize': serializer.toJson<int>(byteSize),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'nextAttemptAt': serializer.toJson<DateTime>(nextAttemptAt),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
      'lastErrorCode': serializer.toJson<String?>(lastErrorCode),
    };
  }

  OutboxItem copyWith({
    String? id,
    String? userId,
    String? commandType,
    String? idempotencyKey,
    Value<String?> projectionId = const Value.absent(),
    Uint8List? encryptedPayload,
    Uint8List? nonce,
    String? status,
    int? attemptCount,
    int? byteSize,
    DateTime? createdAt,
    DateTime? nextAttemptAt,
    DateTime? expiresAt,
    Value<String?> lastErrorCode = const Value.absent(),
  }) => OutboxItem(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    commandType: commandType ?? this.commandType,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    projectionId: projectionId.present ? projectionId.value : this.projectionId,
    encryptedPayload: encryptedPayload ?? this.encryptedPayload,
    nonce: nonce ?? this.nonce,
    status: status ?? this.status,
    attemptCount: attemptCount ?? this.attemptCount,
    byteSize: byteSize ?? this.byteSize,
    createdAt: createdAt ?? this.createdAt,
    nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    expiresAt: expiresAt ?? this.expiresAt,
    lastErrorCode: lastErrorCode.present
        ? lastErrorCode.value
        : this.lastErrorCode,
  );
  OutboxItem copyWithCompanion(OutboxItemsCompanion data) {
    return OutboxItem(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      commandType: data.commandType.present
          ? data.commandType.value
          : this.commandType,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      projectionId: data.projectionId.present
          ? data.projectionId.value
          : this.projectionId,
      encryptedPayload: data.encryptedPayload.present
          ? data.encryptedPayload.value
          : this.encryptedPayload,
      nonce: data.nonce.present ? data.nonce.value : this.nonce,
      status: data.status.present ? data.status.value : this.status,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      byteSize: data.byteSize.present ? data.byteSize.value : this.byteSize,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      lastErrorCode: data.lastErrorCode.present
          ? data.lastErrorCode.value
          : this.lastErrorCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxItem(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('commandType: $commandType, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('projectionId: $projectionId, ')
          ..write('encryptedPayload: $encryptedPayload, ')
          ..write('nonce: $nonce, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('byteSize: $byteSize, ')
          ..write('createdAt: $createdAt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('lastErrorCode: $lastErrorCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    commandType,
    idempotencyKey,
    projectionId,
    $driftBlobEquality.hash(encryptedPayload),
    $driftBlobEquality.hash(nonce),
    status,
    attemptCount,
    byteSize,
    createdAt,
    nextAttemptAt,
    expiresAt,
    lastErrorCode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxItem &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.commandType == this.commandType &&
          other.idempotencyKey == this.idempotencyKey &&
          other.projectionId == this.projectionId &&
          $driftBlobEquality.equals(
            other.encryptedPayload,
            this.encryptedPayload,
          ) &&
          $driftBlobEquality.equals(other.nonce, this.nonce) &&
          other.status == this.status &&
          other.attemptCount == this.attemptCount &&
          other.byteSize == this.byteSize &&
          other.createdAt == this.createdAt &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.expiresAt == this.expiresAt &&
          other.lastErrorCode == this.lastErrorCode);
}

class OutboxItemsCompanion extends UpdateCompanion<OutboxItem> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> commandType;
  final Value<String> idempotencyKey;
  final Value<String?> projectionId;
  final Value<Uint8List> encryptedPayload;
  final Value<Uint8List> nonce;
  final Value<String> status;
  final Value<int> attemptCount;
  final Value<int> byteSize;
  final Value<DateTime> createdAt;
  final Value<DateTime> nextAttemptAt;
  final Value<DateTime> expiresAt;
  final Value<String?> lastErrorCode;
  final Value<int> rowid;
  const OutboxItemsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.commandType = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.projectionId = const Value.absent(),
    this.encryptedPayload = const Value.absent(),
    this.nonce = const Value.absent(),
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxItemsCompanion.insert({
    required String id,
    required String userId,
    required String commandType,
    required String idempotencyKey,
    this.projectionId = const Value.absent(),
    required Uint8List encryptedPayload,
    required Uint8List nonce,
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    required int byteSize,
    required DateTime createdAt,
    required DateTime nextAttemptAt,
    required DateTime expiresAt,
    this.lastErrorCode = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       commandType = Value(commandType),
       idempotencyKey = Value(idempotencyKey),
       encryptedPayload = Value(encryptedPayload),
       nonce = Value(nonce),
       byteSize = Value(byteSize),
       createdAt = Value(createdAt),
       nextAttemptAt = Value(nextAttemptAt),
       expiresAt = Value(expiresAt);
  static Insertable<OutboxItem> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? commandType,
    Expression<String>? idempotencyKey,
    Expression<String>? projectionId,
    Expression<Uint8List>? encryptedPayload,
    Expression<Uint8List>? nonce,
    Expression<String>? status,
    Expression<int>? attemptCount,
    Expression<int>? byteSize,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? nextAttemptAt,
    Expression<DateTime>? expiresAt,
    Expression<String>? lastErrorCode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (commandType != null) 'command_type': commandType,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (projectionId != null) 'projection_id': projectionId,
      if (encryptedPayload != null) 'encrypted_payload': encryptedPayload,
      if (nonce != null) 'nonce': nonce,
      if (status != null) 'status': status,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (byteSize != null) 'byte_size': byteSize,
      if (createdAt != null) 'created_at': createdAt,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (lastErrorCode != null) 'last_error_code': lastErrorCode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? commandType,
    Value<String>? idempotencyKey,
    Value<String?>? projectionId,
    Value<Uint8List>? encryptedPayload,
    Value<Uint8List>? nonce,
    Value<String>? status,
    Value<int>? attemptCount,
    Value<int>? byteSize,
    Value<DateTime>? createdAt,
    Value<DateTime>? nextAttemptAt,
    Value<DateTime>? expiresAt,
    Value<String?>? lastErrorCode,
    Value<int>? rowid,
  }) {
    return OutboxItemsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      commandType: commandType ?? this.commandType,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      projectionId: projectionId ?? this.projectionId,
      encryptedPayload: encryptedPayload ?? this.encryptedPayload,
      nonce: nonce ?? this.nonce,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      byteSize: byteSize ?? this.byteSize,
      createdAt: createdAt ?? this.createdAt,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      expiresAt: expiresAt ?? this.expiresAt,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (commandType.present) {
      map['command_type'] = Variable<String>(commandType.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (projectionId.present) {
      map['projection_id'] = Variable<String>(projectionId.value);
    }
    if (encryptedPayload.present) {
      map['encrypted_payload'] = Variable<Uint8List>(encryptedPayload.value);
    }
    if (nonce.present) {
      map['nonce'] = Variable<Uint8List>(nonce.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (byteSize.present) {
      map['byte_size'] = Variable<int>(byteSize.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (lastErrorCode.present) {
      map['last_error_code'] = Variable<String>(lastErrorCode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxItemsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('commandType: $commandType, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('projectionId: $projectionId, ')
          ..write('encryptedPayload: $encryptedPayload, ')
          ..write('nonce: $nonce, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('byteSize: $byteSize, ')
          ..write('createdAt: $createdAt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ResultProjectionsTable extends ResultProjections
    with TableInfo<$ResultProjectionsTable, ResultProjection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ResultProjectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _characterIdMeta = const VerificationMeta(
    'characterId',
  );
  @override
  late final GeneratedColumn<String> characterId = GeneratedColumn<String>(
    'character_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _validationStatusMeta = const VerificationMeta(
    'validationStatus',
  );
  @override
  late final GeneratedColumn<String> validationStatus = GeneratedColumn<String>(
    'validation_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentVersionMeta = const VerificationMeta(
    'contentVersion',
  );
  @override
  late final GeneratedColumn<String> contentVersion = GeneratedColumn<String>(
    'content_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unknown'),
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelReachedMeta = const VerificationMeta(
    'levelReached',
  );
  @override
  late final GeneratedColumn<int> levelReached = GeneratedColumn<int>(
    'level_reached',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    characterId,
    mode,
    outcome,
    validationStatus,
    contentVersion,
    score,
    durationMs,
    levelReached,
    endedAt,
    isSynced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'result_projections';
  @override
  VerificationContext validateIntegrity(
    Insertable<ResultProjection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('character_id')) {
      context.handle(
        _characterIdMeta,
        characterId.isAcceptableOrUnknown(
          data['character_id']!,
          _characterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    } else if (isInserting) {
      context.missing(_outcomeMeta);
    }
    if (data.containsKey('validation_status')) {
      context.handle(
        _validationStatusMeta,
        validationStatus.isAcceptableOrUnknown(
          data['validation_status']!,
          _validationStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_validationStatusMeta);
    }
    if (data.containsKey('content_version')) {
      context.handle(
        _contentVersionMeta,
        contentVersion.isAcceptableOrUnknown(
          data['content_version']!,
          _contentVersionMeta,
        ),
      );
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('level_reached')) {
      context.handle(
        _levelReachedMeta,
        levelReached.isAcceptableOrUnknown(
          data['level_reached']!,
          _levelReachedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_levelReachedMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endedAtMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ResultProjection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ResultProjection(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      characterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character_id'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome'],
      )!,
      validationStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}validation_status'],
      )!,
      contentVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_version'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      levelReached: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level_reached'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
    );
  }

  @override
  $ResultProjectionsTable createAlias(String alias) {
    return $ResultProjectionsTable(attachedDatabase, alias);
  }
}

class ResultProjection extends DataClass
    implements Insertable<ResultProjection> {
  final String id;
  final String userId;
  final String characterId;
  final String mode;
  final String outcome;
  final String validationStatus;
  final String contentVersion;
  final int score;
  final int durationMs;
  final int levelReached;
  final DateTime endedAt;
  final bool isSynced;
  const ResultProjection({
    required this.id,
    required this.userId,
    required this.characterId,
    required this.mode,
    required this.outcome,
    required this.validationStatus,
    required this.contentVersion,
    required this.score,
    required this.durationMs,
    required this.levelReached,
    required this.endedAt,
    required this.isSynced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['character_id'] = Variable<String>(characterId);
    map['mode'] = Variable<String>(mode);
    map['outcome'] = Variable<String>(outcome);
    map['validation_status'] = Variable<String>(validationStatus);
    map['content_version'] = Variable<String>(contentVersion);
    map['score'] = Variable<int>(score);
    map['duration_ms'] = Variable<int>(durationMs);
    map['level_reached'] = Variable<int>(levelReached);
    map['ended_at'] = Variable<DateTime>(endedAt);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  ResultProjectionsCompanion toCompanion(bool nullToAbsent) {
    return ResultProjectionsCompanion(
      id: Value(id),
      userId: Value(userId),
      characterId: Value(characterId),
      mode: Value(mode),
      outcome: Value(outcome),
      validationStatus: Value(validationStatus),
      contentVersion: Value(contentVersion),
      score: Value(score),
      durationMs: Value(durationMs),
      levelReached: Value(levelReached),
      endedAt: Value(endedAt),
      isSynced: Value(isSynced),
    );
  }

  factory ResultProjection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ResultProjection(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      characterId: serializer.fromJson<String>(json['characterId']),
      mode: serializer.fromJson<String>(json['mode']),
      outcome: serializer.fromJson<String>(json['outcome']),
      validationStatus: serializer.fromJson<String>(json['validationStatus']),
      contentVersion: serializer.fromJson<String>(json['contentVersion']),
      score: serializer.fromJson<int>(json['score']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      levelReached: serializer.fromJson<int>(json['levelReached']),
      endedAt: serializer.fromJson<DateTime>(json['endedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'characterId': serializer.toJson<String>(characterId),
      'mode': serializer.toJson<String>(mode),
      'outcome': serializer.toJson<String>(outcome),
      'validationStatus': serializer.toJson<String>(validationStatus),
      'contentVersion': serializer.toJson<String>(contentVersion),
      'score': serializer.toJson<int>(score),
      'durationMs': serializer.toJson<int>(durationMs),
      'levelReached': serializer.toJson<int>(levelReached),
      'endedAt': serializer.toJson<DateTime>(endedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  ResultProjection copyWith({
    String? id,
    String? userId,
    String? characterId,
    String? mode,
    String? outcome,
    String? validationStatus,
    String? contentVersion,
    int? score,
    int? durationMs,
    int? levelReached,
    DateTime? endedAt,
    bool? isSynced,
  }) => ResultProjection(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    characterId: characterId ?? this.characterId,
    mode: mode ?? this.mode,
    outcome: outcome ?? this.outcome,
    validationStatus: validationStatus ?? this.validationStatus,
    contentVersion: contentVersion ?? this.contentVersion,
    score: score ?? this.score,
    durationMs: durationMs ?? this.durationMs,
    levelReached: levelReached ?? this.levelReached,
    endedAt: endedAt ?? this.endedAt,
    isSynced: isSynced ?? this.isSynced,
  );
  ResultProjection copyWithCompanion(ResultProjectionsCompanion data) {
    return ResultProjection(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      characterId: data.characterId.present
          ? data.characterId.value
          : this.characterId,
      mode: data.mode.present ? data.mode.value : this.mode,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      validationStatus: data.validationStatus.present
          ? data.validationStatus.value
          : this.validationStatus,
      contentVersion: data.contentVersion.present
          ? data.contentVersion.value
          : this.contentVersion,
      score: data.score.present ? data.score.value : this.score,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      levelReached: data.levelReached.present
          ? data.levelReached.value
          : this.levelReached,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ResultProjection(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('characterId: $characterId, ')
          ..write('mode: $mode, ')
          ..write('outcome: $outcome, ')
          ..write('validationStatus: $validationStatus, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('score: $score, ')
          ..write('durationMs: $durationMs, ')
          ..write('levelReached: $levelReached, ')
          ..write('endedAt: $endedAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    characterId,
    mode,
    outcome,
    validationStatus,
    contentVersion,
    score,
    durationMs,
    levelReached,
    endedAt,
    isSynced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ResultProjection &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.characterId == this.characterId &&
          other.mode == this.mode &&
          other.outcome == this.outcome &&
          other.validationStatus == this.validationStatus &&
          other.contentVersion == this.contentVersion &&
          other.score == this.score &&
          other.durationMs == this.durationMs &&
          other.levelReached == this.levelReached &&
          other.endedAt == this.endedAt &&
          other.isSynced == this.isSynced);
}

class ResultProjectionsCompanion extends UpdateCompanion<ResultProjection> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> characterId;
  final Value<String> mode;
  final Value<String> outcome;
  final Value<String> validationStatus;
  final Value<String> contentVersion;
  final Value<int> score;
  final Value<int> durationMs;
  final Value<int> levelReached;
  final Value<DateTime> endedAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const ResultProjectionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.characterId = const Value.absent(),
    this.mode = const Value.absent(),
    this.outcome = const Value.absent(),
    this.validationStatus = const Value.absent(),
    this.contentVersion = const Value.absent(),
    this.score = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.levelReached = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ResultProjectionsCompanion.insert({
    required String id,
    required String userId,
    required String characterId,
    required String mode,
    required String outcome,
    required String validationStatus,
    this.contentVersion = const Value.absent(),
    required int score,
    required int durationMs,
    required int levelReached,
    required DateTime endedAt,
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       characterId = Value(characterId),
       mode = Value(mode),
       outcome = Value(outcome),
       validationStatus = Value(validationStatus),
       score = Value(score),
       durationMs = Value(durationMs),
       levelReached = Value(levelReached),
       endedAt = Value(endedAt);
  static Insertable<ResultProjection> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? characterId,
    Expression<String>? mode,
    Expression<String>? outcome,
    Expression<String>? validationStatus,
    Expression<String>? contentVersion,
    Expression<int>? score,
    Expression<int>? durationMs,
    Expression<int>? levelReached,
    Expression<DateTime>? endedAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (characterId != null) 'character_id': characterId,
      if (mode != null) 'mode': mode,
      if (outcome != null) 'outcome': outcome,
      if (validationStatus != null) 'validation_status': validationStatus,
      if (contentVersion != null) 'content_version': contentVersion,
      if (score != null) 'score': score,
      if (durationMs != null) 'duration_ms': durationMs,
      if (levelReached != null) 'level_reached': levelReached,
      if (endedAt != null) 'ended_at': endedAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ResultProjectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? characterId,
    Value<String>? mode,
    Value<String>? outcome,
    Value<String>? validationStatus,
    Value<String>? contentVersion,
    Value<int>? score,
    Value<int>? durationMs,
    Value<int>? levelReached,
    Value<DateTime>? endedAt,
    Value<bool>? isSynced,
    Value<int>? rowid,
  }) {
    return ResultProjectionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      characterId: characterId ?? this.characterId,
      mode: mode ?? this.mode,
      outcome: outcome ?? this.outcome,
      validationStatus: validationStatus ?? this.validationStatus,
      contentVersion: contentVersion ?? this.contentVersion,
      score: score ?? this.score,
      durationMs: durationMs ?? this.durationMs,
      levelReached: levelReached ?? this.levelReached,
      endedAt: endedAt ?? this.endedAt,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (characterId.present) {
      map['character_id'] = Variable<String>(characterId.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (validationStatus.present) {
      map['validation_status'] = Variable<String>(validationStatus.value);
    }
    if (contentVersion.present) {
      map['content_version'] = Variable<String>(contentVersion.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (levelReached.present) {
      map['level_reached'] = Variable<int>(levelReached.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ResultProjectionsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('characterId: $characterId, ')
          ..write('mode: $mode, ')
          ..write('outcome: $outcome, ')
          ..write('validationStatus: $validationStatus, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('score: $score, ')
          ..write('durationMs: $durationMs, ')
          ..write('levelReached: $levelReached, ')
          ..write('endedAt: $endedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LegacyScoreStatesTable extends LegacyScoreStates
    with TableInfo<$LegacyScoreStatesTable, LegacyScoreState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LegacyScoreStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Récord local heredado'),
  );
  static const VerificationMeta _isUploadedMeta = const VerificationMeta(
    'isUploaded',
  );
  @override
  late final GeneratedColumn<bool> isUploaded = GeneratedColumn<bool>(
    'is_uploaded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_uploaded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _discoveredAtMeta = const VerificationMeta(
    'discoveredAt',
  );
  @override
  late final GeneratedColumn<DateTime> discoveredAt = GeneratedColumn<DateTime>(
    'discovered_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    source,
    score,
    label,
    isUploaded,
    discoveredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'legacy_score_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<LegacyScoreState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('is_uploaded')) {
      context.handle(
        _isUploadedMeta,
        isUploaded.isAcceptableOrUnknown(data['is_uploaded']!, _isUploadedMeta),
      );
    }
    if (data.containsKey('discovered_at')) {
      context.handle(
        _discoveredAtMeta,
        discoveredAt.isAcceptableOrUnknown(
          data['discovered_at']!,
          _discoveredAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_discoveredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {source};
  @override
  LegacyScoreState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LegacyScoreState(
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      isUploaded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_uploaded'],
      )!,
      discoveredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}discovered_at'],
      )!,
    );
  }

  @override
  $LegacyScoreStatesTable createAlias(String alias) {
    return $LegacyScoreStatesTable(attachedDatabase, alias);
  }
}

class LegacyScoreState extends DataClass
    implements Insertable<LegacyScoreState> {
  final String source;
  final int score;
  final String label;
  final bool isUploaded;
  final DateTime discoveredAt;
  const LegacyScoreState({
    required this.source,
    required this.score,
    required this.label,
    required this.isUploaded,
    required this.discoveredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source'] = Variable<String>(source);
    map['score'] = Variable<int>(score);
    map['label'] = Variable<String>(label);
    map['is_uploaded'] = Variable<bool>(isUploaded);
    map['discovered_at'] = Variable<DateTime>(discoveredAt);
    return map;
  }

  LegacyScoreStatesCompanion toCompanion(bool nullToAbsent) {
    return LegacyScoreStatesCompanion(
      source: Value(source),
      score: Value(score),
      label: Value(label),
      isUploaded: Value(isUploaded),
      discoveredAt: Value(discoveredAt),
    );
  }

  factory LegacyScoreState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LegacyScoreState(
      source: serializer.fromJson<String>(json['source']),
      score: serializer.fromJson<int>(json['score']),
      label: serializer.fromJson<String>(json['label']),
      isUploaded: serializer.fromJson<bool>(json['isUploaded']),
      discoveredAt: serializer.fromJson<DateTime>(json['discoveredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'source': serializer.toJson<String>(source),
      'score': serializer.toJson<int>(score),
      'label': serializer.toJson<String>(label),
      'isUploaded': serializer.toJson<bool>(isUploaded),
      'discoveredAt': serializer.toJson<DateTime>(discoveredAt),
    };
  }

  LegacyScoreState copyWith({
    String? source,
    int? score,
    String? label,
    bool? isUploaded,
    DateTime? discoveredAt,
  }) => LegacyScoreState(
    source: source ?? this.source,
    score: score ?? this.score,
    label: label ?? this.label,
    isUploaded: isUploaded ?? this.isUploaded,
    discoveredAt: discoveredAt ?? this.discoveredAt,
  );
  LegacyScoreState copyWithCompanion(LegacyScoreStatesCompanion data) {
    return LegacyScoreState(
      source: data.source.present ? data.source.value : this.source,
      score: data.score.present ? data.score.value : this.score,
      label: data.label.present ? data.label.value : this.label,
      isUploaded: data.isUploaded.present
          ? data.isUploaded.value
          : this.isUploaded,
      discoveredAt: data.discoveredAt.present
          ? data.discoveredAt.value
          : this.discoveredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LegacyScoreState(')
          ..write('source: $source, ')
          ..write('score: $score, ')
          ..write('label: $label, ')
          ..write('isUploaded: $isUploaded, ')
          ..write('discoveredAt: $discoveredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(source, score, label, isUploaded, discoveredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LegacyScoreState &&
          other.source == this.source &&
          other.score == this.score &&
          other.label == this.label &&
          other.isUploaded == this.isUploaded &&
          other.discoveredAt == this.discoveredAt);
}

class LegacyScoreStatesCompanion extends UpdateCompanion<LegacyScoreState> {
  final Value<String> source;
  final Value<int> score;
  final Value<String> label;
  final Value<bool> isUploaded;
  final Value<DateTime> discoveredAt;
  final Value<int> rowid;
  const LegacyScoreStatesCompanion({
    this.source = const Value.absent(),
    this.score = const Value.absent(),
    this.label = const Value.absent(),
    this.isUploaded = const Value.absent(),
    this.discoveredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LegacyScoreStatesCompanion.insert({
    required String source,
    required int score,
    this.label = const Value.absent(),
    this.isUploaded = const Value.absent(),
    required DateTime discoveredAt,
    this.rowid = const Value.absent(),
  }) : source = Value(source),
       score = Value(score),
       discoveredAt = Value(discoveredAt);
  static Insertable<LegacyScoreState> custom({
    Expression<String>? source,
    Expression<int>? score,
    Expression<String>? label,
    Expression<bool>? isUploaded,
    Expression<DateTime>? discoveredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (source != null) 'source': source,
      if (score != null) 'score': score,
      if (label != null) 'label': label,
      if (isUploaded != null) 'is_uploaded': isUploaded,
      if (discoveredAt != null) 'discovered_at': discoveredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LegacyScoreStatesCompanion copyWith({
    Value<String>? source,
    Value<int>? score,
    Value<String>? label,
    Value<bool>? isUploaded,
    Value<DateTime>? discoveredAt,
    Value<int>? rowid,
  }) {
    return LegacyScoreStatesCompanion(
      source: source ?? this.source,
      score: score ?? this.score,
      label: label ?? this.label,
      isUploaded: isUploaded ?? this.isUploaded,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (isUploaded.present) {
      map['is_uploaded'] = Variable<bool>(isUploaded.value);
    }
    if (discoveredAt.present) {
      map['discovered_at'] = Variable<DateTime>(discoveredAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LegacyScoreStatesCompanion(')
          ..write('source: $source, ')
          ..write('score: $score, ')
          ..write('label: $label, ')
          ..write('isUploaded: $isUploaded, ')
          ..write('discoveredAt: $discoveredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UserNamespacesTable userNamespaces = $UserNamespacesTable(this);
  late final $CachedProfilesTable cachedProfiles = $CachedProfilesTable(this);
  late final $OutboxItemsTable outboxItems = $OutboxItemsTable(this);
  late final $ResultProjectionsTable resultProjections =
      $ResultProjectionsTable(this);
  late final $LegacyScoreStatesTable legacyScoreStates =
      $LegacyScoreStatesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    userNamespaces,
    cachedProfiles,
    outboxItems,
    resultProjections,
    legacyScoreStates,
  ];
}

typedef $$UserNamespacesTableCreateCompanionBuilder =
    UserNamespacesCompanion Function({
      required String userId,
      required String protectedScope,
      required bool protectedStorageAvailable,
      required DateTime createdAt,
      required DateTime lastActivatedAt,
      Value<int> rowid,
    });
typedef $$UserNamespacesTableUpdateCompanionBuilder =
    UserNamespacesCompanion Function({
      Value<String> userId,
      Value<String> protectedScope,
      Value<bool> protectedStorageAvailable,
      Value<DateTime> createdAt,
      Value<DateTime> lastActivatedAt,
      Value<int> rowid,
    });

class $$UserNamespacesTableFilterComposer
    extends Composer<_$AppDatabase, $UserNamespacesTable> {
  $$UserNamespacesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get protectedScope => $composableBuilder(
    column: $table.protectedScope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get protectedStorageAvailable => $composableBuilder(
    column: $table.protectedStorageAvailable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastActivatedAt => $composableBuilder(
    column: $table.lastActivatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserNamespacesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserNamespacesTable> {
  $$UserNamespacesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get protectedScope => $composableBuilder(
    column: $table.protectedScope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get protectedStorageAvailable => $composableBuilder(
    column: $table.protectedStorageAvailable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastActivatedAt => $composableBuilder(
    column: $table.lastActivatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserNamespacesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserNamespacesTable> {
  $$UserNamespacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get protectedScope => $composableBuilder(
    column: $table.protectedScope,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get protectedStorageAvailable => $composableBuilder(
    column: $table.protectedStorageAvailable,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastActivatedAt => $composableBuilder(
    column: $table.lastActivatedAt,
    builder: (column) => column,
  );
}

class $$UserNamespacesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserNamespacesTable,
          UserNamespace,
          $$UserNamespacesTableFilterComposer,
          $$UserNamespacesTableOrderingComposer,
          $$UserNamespacesTableAnnotationComposer,
          $$UserNamespacesTableCreateCompanionBuilder,
          $$UserNamespacesTableUpdateCompanionBuilder,
          (
            UserNamespace,
            BaseReferences<_$AppDatabase, $UserNamespacesTable, UserNamespace>,
          ),
          UserNamespace,
          PrefetchHooks Function()
        > {
  $$UserNamespacesTableTableManager(
    _$AppDatabase db,
    $UserNamespacesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserNamespacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserNamespacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserNamespacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> protectedScope = const Value.absent(),
                Value<bool> protectedStorageAvailable = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastActivatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserNamespacesCompanion(
                userId: userId,
                protectedScope: protectedScope,
                protectedStorageAvailable: protectedStorageAvailable,
                createdAt: createdAt,
                lastActivatedAt: lastActivatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String protectedScope,
                required bool protectedStorageAvailable,
                required DateTime createdAt,
                required DateTime lastActivatedAt,
                Value<int> rowid = const Value.absent(),
              }) => UserNamespacesCompanion.insert(
                userId: userId,
                protectedScope: protectedScope,
                protectedStorageAvailable: protectedStorageAvailable,
                createdAt: createdAt,
                lastActivatedAt: lastActivatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserNamespacesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserNamespacesTable,
      UserNamespace,
      $$UserNamespacesTableFilterComposer,
      $$UserNamespacesTableOrderingComposer,
      $$UserNamespacesTableAnnotationComposer,
      $$UserNamespacesTableCreateCompanionBuilder,
      $$UserNamespacesTableUpdateCompanionBuilder,
      (
        UserNamespace,
        BaseReferences<_$AppDatabase, $UserNamespacesTable, UserNamespace>,
      ),
      UserNamespace,
      PrefetchHooks Function()
    >;
typedef $$CachedProfilesTableCreateCompanionBuilder =
    CachedProfilesCompanion Function({
      required String userId,
      required String email,
      required String displayName,
      required bool emailVerified,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CachedProfilesTableUpdateCompanionBuilder =
    CachedProfilesCompanion Function({
      Value<String> userId,
      Value<String> email,
      Value<String> displayName,
      Value<bool> emailVerified,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CachedProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedProfilesTable> {
  $$CachedProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get emailVerified => $composableBuilder(
    column: $table.emailVerified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedProfilesTable> {
  $$CachedProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get emailVerified => $composableBuilder(
    column: $table.emailVerified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedProfilesTable> {
  $$CachedProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get emailVerified => $composableBuilder(
    column: $table.emailVerified,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedProfilesTable,
          CachedProfile,
          $$CachedProfilesTableFilterComposer,
          $$CachedProfilesTableOrderingComposer,
          $$CachedProfilesTableAnnotationComposer,
          $$CachedProfilesTableCreateCompanionBuilder,
          $$CachedProfilesTableUpdateCompanionBuilder,
          (
            CachedProfile,
            BaseReferences<_$AppDatabase, $CachedProfilesTable, CachedProfile>,
          ),
          CachedProfile,
          PrefetchHooks Function()
        > {
  $$CachedProfilesTableTableManager(
    _$AppDatabase db,
    $CachedProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<bool> emailVerified = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedProfilesCompanion(
                userId: userId,
                email: email,
                displayName: displayName,
                emailVerified: emailVerified,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String email,
                required String displayName,
                required bool emailVerified,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedProfilesCompanion.insert(
                userId: userId,
                email: email,
                displayName: displayName,
                emailVerified: emailVerified,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedProfilesTable,
      CachedProfile,
      $$CachedProfilesTableFilterComposer,
      $$CachedProfilesTableOrderingComposer,
      $$CachedProfilesTableAnnotationComposer,
      $$CachedProfilesTableCreateCompanionBuilder,
      $$CachedProfilesTableUpdateCompanionBuilder,
      (
        CachedProfile,
        BaseReferences<_$AppDatabase, $CachedProfilesTable, CachedProfile>,
      ),
      CachedProfile,
      PrefetchHooks Function()
    >;
typedef $$OutboxItemsTableCreateCompanionBuilder =
    OutboxItemsCompanion Function({
      required String id,
      required String userId,
      required String commandType,
      required String idempotencyKey,
      Value<String?> projectionId,
      required Uint8List encryptedPayload,
      required Uint8List nonce,
      Value<String> status,
      Value<int> attemptCount,
      required int byteSize,
      required DateTime createdAt,
      required DateTime nextAttemptAt,
      required DateTime expiresAt,
      Value<String?> lastErrorCode,
      Value<int> rowid,
    });
typedef $$OutboxItemsTableUpdateCompanionBuilder =
    OutboxItemsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> commandType,
      Value<String> idempotencyKey,
      Value<String?> projectionId,
      Value<Uint8List> encryptedPayload,
      Value<Uint8List> nonce,
      Value<String> status,
      Value<int> attemptCount,
      Value<int> byteSize,
      Value<DateTime> createdAt,
      Value<DateTime> nextAttemptAt,
      Value<DateTime> expiresAt,
      Value<String?> lastErrorCode,
      Value<int> rowid,
    });

class $$OutboxItemsTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxItemsTable> {
  $$OutboxItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get commandType => $composableBuilder(
    column: $table.commandType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectionId => $composableBuilder(
    column: $table.projectionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get encryptedPayload => $composableBuilder(
    column: $table.encryptedPayload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get nonce => $composableBuilder(
    column: $table.nonce,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxItemsTable> {
  $$OutboxItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get commandType => $composableBuilder(
    column: $table.commandType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectionId => $composableBuilder(
    column: $table.projectionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get encryptedPayload => $composableBuilder(
    column: $table.encryptedPayload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get nonce => $composableBuilder(
    column: $table.nonce,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxItemsTable> {
  $$OutboxItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get commandType => $composableBuilder(
    column: $table.commandType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get projectionId => $composableBuilder(
    column: $table.projectionId,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get encryptedPayload => $composableBuilder(
    column: $table.encryptedPayload,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get nonce =>
      $composableBuilder(column: $table.nonce, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get byteSize =>
      $composableBuilder(column: $table.byteSize, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => column,
  );
}

class $$OutboxItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxItemsTable,
          OutboxItem,
          $$OutboxItemsTableFilterComposer,
          $$OutboxItemsTableOrderingComposer,
          $$OutboxItemsTableAnnotationComposer,
          $$OutboxItemsTableCreateCompanionBuilder,
          $$OutboxItemsTableUpdateCompanionBuilder,
          (
            OutboxItem,
            BaseReferences<_$AppDatabase, $OutboxItemsTable, OutboxItem>,
          ),
          OutboxItem,
          PrefetchHooks Function()
        > {
  $$OutboxItemsTableTableManager(_$AppDatabase db, $OutboxItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> commandType = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String?> projectionId = const Value.absent(),
                Value<Uint8List> encryptedPayload = const Value.absent(),
                Value<Uint8List> nonce = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<int> byteSize = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> nextAttemptAt = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxItemsCompanion(
                id: id,
                userId: userId,
                commandType: commandType,
                idempotencyKey: idempotencyKey,
                projectionId: projectionId,
                encryptedPayload: encryptedPayload,
                nonce: nonce,
                status: status,
                attemptCount: attemptCount,
                byteSize: byteSize,
                createdAt: createdAt,
                nextAttemptAt: nextAttemptAt,
                expiresAt: expiresAt,
                lastErrorCode: lastErrorCode,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String commandType,
                required String idempotencyKey,
                Value<String?> projectionId = const Value.absent(),
                required Uint8List encryptedPayload,
                required Uint8List nonce,
                Value<String> status = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                required int byteSize,
                required DateTime createdAt,
                required DateTime nextAttemptAt,
                required DateTime expiresAt,
                Value<String?> lastErrorCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxItemsCompanion.insert(
                id: id,
                userId: userId,
                commandType: commandType,
                idempotencyKey: idempotencyKey,
                projectionId: projectionId,
                encryptedPayload: encryptedPayload,
                nonce: nonce,
                status: status,
                attemptCount: attemptCount,
                byteSize: byteSize,
                createdAt: createdAt,
                nextAttemptAt: nextAttemptAt,
                expiresAt: expiresAt,
                lastErrorCode: lastErrorCode,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxItemsTable,
      OutboxItem,
      $$OutboxItemsTableFilterComposer,
      $$OutboxItemsTableOrderingComposer,
      $$OutboxItemsTableAnnotationComposer,
      $$OutboxItemsTableCreateCompanionBuilder,
      $$OutboxItemsTableUpdateCompanionBuilder,
      (
        OutboxItem,
        BaseReferences<_$AppDatabase, $OutboxItemsTable, OutboxItem>,
      ),
      OutboxItem,
      PrefetchHooks Function()
    >;
typedef $$ResultProjectionsTableCreateCompanionBuilder =
    ResultProjectionsCompanion Function({
      required String id,
      required String userId,
      required String characterId,
      required String mode,
      required String outcome,
      required String validationStatus,
      Value<String> contentVersion,
      required int score,
      required int durationMs,
      required int levelReached,
      required DateTime endedAt,
      Value<bool> isSynced,
      Value<int> rowid,
    });
typedef $$ResultProjectionsTableUpdateCompanionBuilder =
    ResultProjectionsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> characterId,
      Value<String> mode,
      Value<String> outcome,
      Value<String> validationStatus,
      Value<String> contentVersion,
      Value<int> score,
      Value<int> durationMs,
      Value<int> levelReached,
      Value<DateTime> endedAt,
      Value<bool> isSynced,
      Value<int> rowid,
    });

class $$ResultProjectionsTableFilterComposer
    extends Composer<_$AppDatabase, $ResultProjectionsTable> {
  $$ResultProjectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get validationStatus => $composableBuilder(
    column: $table.validationStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get levelReached => $composableBuilder(
    column: $table.levelReached,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ResultProjectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ResultProjectionsTable> {
  $$ResultProjectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get validationStatus => $composableBuilder(
    column: $table.validationStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get levelReached => $composableBuilder(
    column: $table.levelReached,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ResultProjectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ResultProjectionsTable> {
  $$ResultProjectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<String> get validationStatus => $composableBuilder(
    column: $table.validationStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get levelReached => $composableBuilder(
    column: $table.levelReached,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$ResultProjectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ResultProjectionsTable,
          ResultProjection,
          $$ResultProjectionsTableFilterComposer,
          $$ResultProjectionsTableOrderingComposer,
          $$ResultProjectionsTableAnnotationComposer,
          $$ResultProjectionsTableCreateCompanionBuilder,
          $$ResultProjectionsTableUpdateCompanionBuilder,
          (
            ResultProjection,
            BaseReferences<
              _$AppDatabase,
              $ResultProjectionsTable,
              ResultProjection
            >,
          ),
          ResultProjection,
          PrefetchHooks Function()
        > {
  $$ResultProjectionsTableTableManager(
    _$AppDatabase db,
    $ResultProjectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ResultProjectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ResultProjectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ResultProjectionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> characterId = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String> outcome = const Value.absent(),
                Value<String> validationStatus = const Value.absent(),
                Value<String> contentVersion = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<int> levelReached = const Value.absent(),
                Value<DateTime> endedAt = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ResultProjectionsCompanion(
                id: id,
                userId: userId,
                characterId: characterId,
                mode: mode,
                outcome: outcome,
                validationStatus: validationStatus,
                contentVersion: contentVersion,
                score: score,
                durationMs: durationMs,
                levelReached: levelReached,
                endedAt: endedAt,
                isSynced: isSynced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String characterId,
                required String mode,
                required String outcome,
                required String validationStatus,
                Value<String> contentVersion = const Value.absent(),
                required int score,
                required int durationMs,
                required int levelReached,
                required DateTime endedAt,
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ResultProjectionsCompanion.insert(
                id: id,
                userId: userId,
                characterId: characterId,
                mode: mode,
                outcome: outcome,
                validationStatus: validationStatus,
                contentVersion: contentVersion,
                score: score,
                durationMs: durationMs,
                levelReached: levelReached,
                endedAt: endedAt,
                isSynced: isSynced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ResultProjectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ResultProjectionsTable,
      ResultProjection,
      $$ResultProjectionsTableFilterComposer,
      $$ResultProjectionsTableOrderingComposer,
      $$ResultProjectionsTableAnnotationComposer,
      $$ResultProjectionsTableCreateCompanionBuilder,
      $$ResultProjectionsTableUpdateCompanionBuilder,
      (
        ResultProjection,
        BaseReferences<
          _$AppDatabase,
          $ResultProjectionsTable,
          ResultProjection
        >,
      ),
      ResultProjection,
      PrefetchHooks Function()
    >;
typedef $$LegacyScoreStatesTableCreateCompanionBuilder =
    LegacyScoreStatesCompanion Function({
      required String source,
      required int score,
      Value<String> label,
      Value<bool> isUploaded,
      required DateTime discoveredAt,
      Value<int> rowid,
    });
typedef $$LegacyScoreStatesTableUpdateCompanionBuilder =
    LegacyScoreStatesCompanion Function({
      Value<String> source,
      Value<int> score,
      Value<String> label,
      Value<bool> isUploaded,
      Value<DateTime> discoveredAt,
      Value<int> rowid,
    });

class $$LegacyScoreStatesTableFilterComposer
    extends Composer<_$AppDatabase, $LegacyScoreStatesTable> {
  $$LegacyScoreStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isUploaded => $composableBuilder(
    column: $table.isUploaded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get discoveredAt => $composableBuilder(
    column: $table.discoveredAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LegacyScoreStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $LegacyScoreStatesTable> {
  $$LegacyScoreStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isUploaded => $composableBuilder(
    column: $table.isUploaded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get discoveredAt => $composableBuilder(
    column: $table.discoveredAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LegacyScoreStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LegacyScoreStatesTable> {
  $$LegacyScoreStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<bool> get isUploaded => $composableBuilder(
    column: $table.isUploaded,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get discoveredAt => $composableBuilder(
    column: $table.discoveredAt,
    builder: (column) => column,
  );
}

class $$LegacyScoreStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LegacyScoreStatesTable,
          LegacyScoreState,
          $$LegacyScoreStatesTableFilterComposer,
          $$LegacyScoreStatesTableOrderingComposer,
          $$LegacyScoreStatesTableAnnotationComposer,
          $$LegacyScoreStatesTableCreateCompanionBuilder,
          $$LegacyScoreStatesTableUpdateCompanionBuilder,
          (
            LegacyScoreState,
            BaseReferences<
              _$AppDatabase,
              $LegacyScoreStatesTable,
              LegacyScoreState
            >,
          ),
          LegacyScoreState,
          PrefetchHooks Function()
        > {
  $$LegacyScoreStatesTableTableManager(
    _$AppDatabase db,
    $LegacyScoreStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LegacyScoreStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LegacyScoreStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LegacyScoreStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> source = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<bool> isUploaded = const Value.absent(),
                Value<DateTime> discoveredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LegacyScoreStatesCompanion(
                source: source,
                score: score,
                label: label,
                isUploaded: isUploaded,
                discoveredAt: discoveredAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String source,
                required int score,
                Value<String> label = const Value.absent(),
                Value<bool> isUploaded = const Value.absent(),
                required DateTime discoveredAt,
                Value<int> rowid = const Value.absent(),
              }) => LegacyScoreStatesCompanion.insert(
                source: source,
                score: score,
                label: label,
                isUploaded: isUploaded,
                discoveredAt: discoveredAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LegacyScoreStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LegacyScoreStatesTable,
      LegacyScoreState,
      $$LegacyScoreStatesTableFilterComposer,
      $$LegacyScoreStatesTableOrderingComposer,
      $$LegacyScoreStatesTableAnnotationComposer,
      $$LegacyScoreStatesTableCreateCompanionBuilder,
      $$LegacyScoreStatesTableUpdateCompanionBuilder,
      (
        LegacyScoreState,
        BaseReferences<
          _$AppDatabase,
          $LegacyScoreStatesTable,
          LegacyScoreState
        >,
      ),
      LegacyScoreState,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UserNamespacesTableTableManager get userNamespaces =>
      $$UserNamespacesTableTableManager(_db, _db.userNamespaces);
  $$CachedProfilesTableTableManager get cachedProfiles =>
      $$CachedProfilesTableTableManager(_db, _db.cachedProfiles);
  $$OutboxItemsTableTableManager get outboxItems =>
      $$OutboxItemsTableTableManager(_db, _db.outboxItems);
  $$ResultProjectionsTableTableManager get resultProjections =>
      $$ResultProjectionsTableTableManager(_db, _db.resultProjections);
  $$LegacyScoreStatesTableTableManager get legacyScoreStates =>
      $$LegacyScoreStatesTableTableManager(_db, _db.legacyScoreStates);
}

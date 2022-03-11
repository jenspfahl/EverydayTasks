// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static _$AppDatabaseBuilder databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static _$AppDatabaseBuilder inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  /// Adds migrations to the builder.
  _$AppDatabaseBuilder addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  /// Adds a database [Callback] to the builder.
  _$AppDatabaseBuilder addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  /// Creates the database and initializes it.
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  TaskEventDao? _taskEventDaoInstance;

  TaskTemplateDao? _taskTemplateDaoInstance;

  TaskTemplateVariantDao? _taskTemplateVariantDaoInstance;

  ScheduledTaskDao? _scheduledTaskDaoInstance;

  ScheduledTaskEventDao? _scheduledTaskEventDaoInstance;

  Future<sqflite.Database> open(String path, List<Migration> migrations,
      [Callback? callback]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 5,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `TaskEventEntity` (`id` INTEGER, `taskGroupId` INTEGER, `originTaskTemplateId` INTEGER, `originTaskTemplateVariantId` INTEGER, `title` TEXT NOT NULL, `description` TEXT, `createdAt` INTEGER NOT NULL, `startedAt` INTEGER NOT NULL, `aroundStartedAt` INTEGER NOT NULL, `duration` INTEGER NOT NULL, `aroundDuration` INTEGER NOT NULL, `severity` INTEGER NOT NULL, `favorite` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `TaskTemplateEntity` (`id` INTEGER, `taskGroupId` INTEGER NOT NULL, `title` TEXT NOT NULL, `description` TEXT, `startedAt` INTEGER, `aroundStartedAt` INTEGER, `duration` INTEGER, `aroundDuration` INTEGER, `severity` INTEGER, `favorite` INTEGER NOT NULL, `hidden` INTEGER, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `TaskTemplateVariantEntity` (`id` INTEGER, `taskGroupId` INTEGER NOT NULL, `taskTemplateId` INTEGER NOT NULL, `title` TEXT NOT NULL, `description` TEXT, `startedAt` INTEGER, `aroundStartedAt` INTEGER, `duration` INTEGER, `aroundDuration` INTEGER, `severity` INTEGER, `favorite` INTEGER NOT NULL, `hidden` INTEGER, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `ScheduledTaskEntity` (`id` INTEGER, `taskGroupId` INTEGER NOT NULL, `taskTemplateId` INTEGER, `taskTemplateVariantId` INTEGER, `title` TEXT NOT NULL, `description` TEXT, `createdAt` INTEGER NOT NULL, `aroundStartAt` INTEGER NOT NULL, `startAt` INTEGER, `repetitionAfter` INTEGER NOT NULL, `exactRepetitionAfter` INTEGER, `exactRepetitionAfterUnit` INTEGER, `lastScheduledEventAt` INTEGER, `active` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `ScheduledTaskEventEntity` (`id` INTEGER, `taskEventId` INTEGER NOT NULL, `scheduledTaskId` INTEGER NOT NULL, `createdAt` INTEGER NOT NULL, PRIMARY KEY (`id`))');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  TaskEventDao get taskEventDao {
    return _taskEventDaoInstance ??= _$TaskEventDao(database, changeListener);
  }

  @override
  TaskTemplateDao get taskTemplateDao {
    return _taskTemplateDaoInstance ??=
        _$TaskTemplateDao(database, changeListener);
  }

  @override
  TaskTemplateVariantDao get taskTemplateVariantDao {
    return _taskTemplateVariantDaoInstance ??=
        _$TaskTemplateVariantDao(database, changeListener);
  }

  @override
  ScheduledTaskDao get scheduledTaskDao {
    return _scheduledTaskDaoInstance ??=
        _$ScheduledTaskDao(database, changeListener);
  }

  @override
  ScheduledTaskEventDao get scheduledTaskEventDao {
    return _scheduledTaskEventDaoInstance ??=
        _$ScheduledTaskEventDao(database, changeListener);
  }
}

class _$TaskEventDao extends TaskEventDao {
  _$TaskEventDao(this.database, this.changeListener)
      : _queryAdapter = QueryAdapter(database, changeListener),
        _taskEventEntityInsertionAdapter = InsertionAdapter(
            database,
            'TaskEventEntity',
            (TaskEventEntity item) => <String, Object?>{
                  'id': item.id,
                  'taskGroupId': item.taskGroupId,
                  'originTaskTemplateId': item.originTaskTemplateId,
                  'originTaskTemplateVariantId':
                      item.originTaskTemplateVariantId,
                  'title': item.title,
                  'description': item.description,
                  'createdAt': item.createdAt,
                  'startedAt': item.startedAt,
                  'aroundStartedAt': item.aroundStartedAt,
                  'duration': item.duration,
                  'aroundDuration': item.aroundDuration,
                  'severity': item.severity,
                  'favorite': item.favorite ? 1 : 0
                },
            changeListener),
        _taskEventEntityUpdateAdapter = UpdateAdapter(
            database,
            'TaskEventEntity',
            ['id'],
            (TaskEventEntity item) => <String, Object?>{
                  'id': item.id,
                  'taskGroupId': item.taskGroupId,
                  'originTaskTemplateId': item.originTaskTemplateId,
                  'originTaskTemplateVariantId':
                      item.originTaskTemplateVariantId,
                  'title': item.title,
                  'description': item.description,
                  'createdAt': item.createdAt,
                  'startedAt': item.startedAt,
                  'aroundStartedAt': item.aroundStartedAt,
                  'duration': item.duration,
                  'aroundDuration': item.aroundDuration,
                  'severity': item.severity,
                  'favorite': item.favorite ? 1 : 0
                },
            changeListener),
        _taskEventEntityDeletionAdapter = DeletionAdapter(
            database,
            'TaskEventEntity',
            ['id'],
            (TaskEventEntity item) => <String, Object?>{
                  'id': item.id,
                  'taskGroupId': item.taskGroupId,
                  'originTaskTemplateId': item.originTaskTemplateId,
                  'originTaskTemplateVariantId':
                      item.originTaskTemplateVariantId,
                  'title': item.title,
                  'description': item.description,
                  'createdAt': item.createdAt,
                  'startedAt': item.startedAt,
                  'aroundStartedAt': item.aroundStartedAt,
                  'duration': item.duration,
                  'aroundDuration': item.aroundDuration,
                  'severity': item.severity,
                  'favorite': item.favorite ? 1 : 0
                },
            changeListener);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<TaskEventEntity> _taskEventEntityInsertionAdapter;

  final UpdateAdapter<TaskEventEntity> _taskEventEntityUpdateAdapter;

  final DeletionAdapter<TaskEventEntity> _taskEventEntityDeletionAdapter;

  @override
  Future<List<TaskEventEntity>> findAllBeginningByStartedAt(
      int lastStartedAt, int lastId, int limit) async {
    return _queryAdapter.queryList(
        'SELECT * FROM TaskEventEntity WHERE startedAt < ?1 AND id < ?2 ORDER BY startedAt DESC, id DESC LIMIT ?3',
        mapper: (Map<String, Object?> row) => TaskEventEntity(row['id'] as int?, row['taskGroupId'] as int?, row['originTaskTemplateId'] as int?, row['originTaskTemplateVariantId'] as int?, row['title'] as String, row['description'] as String?, row['createdAt'] as int, row['startedAt'] as int, row['aroundStartedAt'] as int, row['duration'] as int, row['aroundDuration'] as int, row['severity'] as int, (row['favorite'] as int) != 0),
        arguments: [lastStartedAt, lastId, limit]);
  }

  @override
  Stream<TaskEventEntity?> findById(int id) {
    return _queryAdapter.queryStream(
        'SELECT * FROM TaskEventEntity WHERE id = ?1',
        mapper: (Map<String, Object?> row) => TaskEventEntity(
            row['id'] as int?,
            row['taskGroupId'] as int?,
            row['originTaskTemplateId'] as int?,
            row['originTaskTemplateVariantId'] as int?,
            row['title'] as String,
            row['description'] as String?,
            row['createdAt'] as int,
            row['startedAt'] as int,
            row['aroundStartedAt'] as int,
            row['duration'] as int,
            row['aroundDuration'] as int,
            row['severity'] as int,
            (row['favorite'] as int) != 0),
        arguments: [id],
        queryableName: 'TaskEventEntity',
        isView: false);
  }

  @override
  Future<int> insertTaskEvent(TaskEventEntity taskEvent) {
    return _taskEventEntityInsertionAdapter.insertAndReturnId(
        taskEvent, OnConflictStrategy.abort);
  }

  @override
  Future<int> updateTaskEvent(TaskEventEntity taskEvent) {
    return _taskEventEntityUpdateAdapter.updateAndReturnChangedRows(
        taskEvent, OnConflictStrategy.abort);
  }

  @override
  Future<int> deleteTaskEvent(TaskEventEntity taskEvent) {
    return _taskEventEntityDeletionAdapter
        .deleteAndReturnChangedRows(taskEvent);
  }
}

class _$TaskTemplateDao extends TaskTemplateDao {
  _$TaskTemplateDao(this.database, this.changeListener)
      : _queryAdapter = QueryAdapter(database, changeListener),
        _taskTemplateEntityInsertionAdapter = InsertionAdapter(
            database,
            'TaskTemplateEntity',
            (TaskTemplateEntity item) => <String, Object?>{
                  'id': item.id,
                  'taskGroupId': item.taskGroupId,
                  'title': item.title,
                  'description': item.description,
                  'startedAt': item.startedAt,
                  'aroundStartedAt': item.aroundStartedAt,
                  'duration': item.duration,
                  'aroundDuration': item.aroundDuration,
                  'severity': item.severity,
                  'favorite': item.favorite ? 1 : 0,
                  'hidden': item.hidden == null ? null : (item.hidden! ? 1 : 0)
                },
            changeListener),
        _taskTemplateEntityUpdateAdapter = UpdateAdapter(
            database,
            'TaskTemplateEntity',
            ['id'],
            (TaskTemplateEntity item) => <String, Object?>{
                  'id': item.id,
                  'taskGroupId': item.taskGroupId,
                  'title': item.title,
                  'description': item.description,
                  'startedAt': item.startedAt,
                  'aroundStartedAt': item.aroundStartedAt,
                  'duration': item.duration,
                  'aroundDuration': item.aroundDuration,
                  'severity': item.severity,
                  'favorite': item.favorite ? 1 : 0,
                  'hidden': item.hidden == null ? null : (item.hidden! ? 1 : 0)
                },
            changeListener),
        _taskTemplateEntityDeletionAdapter = DeletionAdapter(
            database,
            'TaskTemplateEntity',
            ['id'],
            (TaskTemplateEntity item) => <String, Object?>{
                  'id': item.id,
                  'taskGroupId': item.taskGroupId,
                  'title': item.title,
                  'description': item.description,
                  'startedAt': item.startedAt,
                  'aroundStartedAt': item.aroundStartedAt,
                  'duration': item.duration,
                  'aroundDuration': item.aroundDuration,
                  'severity': item.severity,
                  'favorite': item.favorite ? 1 : 0,
                  'hidden': item.hidden == null ? null : (item.hidden! ? 1 : 0)
                },
            changeListener);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<TaskTemplateEntity>
      _taskTemplateEntityInsertionAdapter;

  final UpdateAdapter<TaskTemplateEntity> _taskTemplateEntityUpdateAdapter;

  final DeletionAdapter<TaskTemplateEntity> _taskTemplateEntityDeletionAdapter;

  @override
  Future<List<TaskTemplateEntity>> findAll() async {
    return _queryAdapter.queryList(
        'SELECT * FROM TaskTemplateEntity ORDER BY id DESC',
        mapper: (Map<String, Object?> row) => TaskTemplateEntity(
            row['id'] as int?,
            row['taskGroupId'] as int,
            row['title'] as String,
            row['description'] as String?,
            row['startedAt'] as int?,
            row['aroundStartedAt'] as int?,
            row['duration'] as int?,
            row['aroundDuration'] as int?,
            row['severity'] as int?,
            (row['favorite'] as int) != 0,
            row['hidden'] == null ? null : (row['hidden'] as int) != 0));
  }

  // !!!! this was generated wrong. Hard implemented !!!
  @override
  Future<int?> findMaxId() async {
    return _queryAdapter.query(
        'SELECT MAX(id) as MAX_ID FROM TaskTemplateEntity',
        mapper: (Map<String, Object?> row) => row['MAX_ID'] as int? ?? 0);
  }
  // !!!! this was generated wrong. Hard implemented !!!

  @override
  Stream<TaskTemplateEntity?> findById(int id) {
    return _queryAdapter.queryStream(
        'SELECT * FROM TaskTemplateEntity WHERE id = ?1',
        mapper: (Map<String, Object?> row) => TaskTemplateEntity(
            row['id'] as int?,
            row['taskGroupId'] as int,
            row['title'] as String,
            row['description'] as String?,
            row['startedAt'] as int?,
            row['aroundStartedAt'] as int?,
            row['duration'] as int?,
            row['aroundDuration'] as int?,
            row['severity'] as int?,
            (row['favorite'] as int) != 0,
            row['hidden'] == null ? null : (row['hidden'] as int) != 0),
        arguments: [id],
        queryableName: 'TaskTemplateEntity',
        isView: false);
  }

  @override
  Future<int> insertTaskTemplate(TaskTemplateEntity taskTemplate) {
    return _taskTemplateEntityInsertionAdapter.insertAndReturnId(
        taskTemplate, OnConflictStrategy.abort);
  }

  @override
  Future<int> updateTaskTemplate(TaskTemplateEntity taskTemplate) {
    return _taskTemplateEntityUpdateAdapter.updateAndReturnChangedRows(
        taskTemplate, OnConflictStrategy.abort);
  }

  @override
  Future<int> deleteTaskTemplate(TaskTemplateEntity taskTemplate) {
    return _taskTemplateEntityDeletionAdapter
        .deleteAndReturnChangedRows(taskTemplate);
  }
}

class _$TaskTemplateVariantDao extends TaskTemplateVariantDao {
  _$TaskTemplateVariantDao(this.database, this.changeListener)
      : _queryAdapter = QueryAdapter(database, changeListener),
        _taskTemplateVariantEntityInsertionAdapter = InsertionAdapter(
            database,
            'TaskTemplateVariantEntity',
            (TaskTemplateVariantEntity item) => <String, Object?>{
                  'id': item.id,
                  'taskGroupId': item.taskGroupId,
                  'taskTemplateId': item.taskTemplateId,
                  'title': item.title,
                  'description': item.description,
                  'startedAt': item.startedAt,
                  'aroundStartedAt': item.aroundStartedAt,
                  'duration': item.duration,
                  'aroundDuration': item.aroundDuration,
                  'severity': item.severity,
                  'favorite': item.favorite ? 1 : 0,
                  'hidden': item.hidden == null ? null : (item.hidden! ? 1 : 0)
                },
            changeListener),
        _taskTemplateVariantEntityUpdateAdapter = UpdateAdapter(
            database,
            'TaskTemplateVariantEntity',
            ['id'],
            (TaskTemplateVariantEntity item) => <String, Object?>{
                  'id': item.id,
                  'taskGroupId': item.taskGroupId,
                  'taskTemplateId': item.taskTemplateId,
                  'title': item.title,
                  'description': item.description,
                  'startedAt': item.startedAt,
                  'aroundStartedAt': item.aroundStartedAt,
                  'duration': item.duration,
                  'aroundDuration': item.aroundDuration,
                  'severity': item.severity,
                  'favorite': item.favorite ? 1 : 0,
                  'hidden': item.hidden == null ? null : (item.hidden! ? 1 : 0)
                },
            changeListener),
        _taskTemplateVariantEntityDeletionAdapter = DeletionAdapter(
            database,
            'TaskTemplateVariantEntity',
            ['id'],
            (TaskTemplateVariantEntity item) => <String, Object?>{
                  'id': item.id,
                  'taskGroupId': item.taskGroupId,
                  'taskTemplateId': item.taskTemplateId,
                  'title': item.title,
                  'description': item.description,
                  'startedAt': item.startedAt,
                  'aroundStartedAt': item.aroundStartedAt,
                  'duration': item.duration,
                  'aroundDuration': item.aroundDuration,
                  'severity': item.severity,
                  'favorite': item.favorite ? 1 : 0,
                  'hidden': item.hidden == null ? null : (item.hidden! ? 1 : 0)
                },
            changeListener);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<TaskTemplateVariantEntity>
      _taskTemplateVariantEntityInsertionAdapter;

  final UpdateAdapter<TaskTemplateVariantEntity>
      _taskTemplateVariantEntityUpdateAdapter;

  final DeletionAdapter<TaskTemplateVariantEntity>
      _taskTemplateVariantEntityDeletionAdapter;

  @override
  Future<List<TaskTemplateVariantEntity>> findAll() async {
    return _queryAdapter.queryList(
        'SELECT * FROM TaskTemplateVariantEntity ORDER BY id DESC',
        mapper: (Map<String, Object?> row) => TaskTemplateVariantEntity(
            row['id'] as int?,
            row['taskGroupId'] as int,
            row['taskTemplateId'] as int,
            row['title'] as String,
            row['description'] as String?,
            row['startedAt'] as int?,
            row['aroundStartedAt'] as int?,
            row['duration'] as int?,
            row['aroundDuration'] as int?,
            row['severity'] as int?,
            (row['favorite'] as int) != 0,
            row['hidden'] == null ? null : (row['hidden'] as int) != 0));
  }

  // !!!! this was generated wrong. Hard implemented !!!
  @override
  Future<int?> findMaxId() async {
    return _queryAdapter.query(
        'SELECT MAX(id) as MAX_ID FROM TaskTemplateVariantEntity',
        mapper: (Map<String, Object?> row) => row['MAX_ID'] as int? ?? 0);
  }
  // !!!! this was generated wrong. Hard implemented !!!

  @override
  Future<List<TaskTemplateVariantEntity>> findAllFavs() async {
    return _queryAdapter.queryList(
        'SELECT * FROM TaskTemplateVariantEntity ORDER BY id DESC',
        mapper: (Map<String, Object?> row) => TaskTemplateVariantEntity(
            row['id'] as int?,
            row['taskGroupId'] as int,
            row['taskTemplateId'] as int,
            row['title'] as String,
            row['description'] as String?,
            row['startedAt'] as int?,
            row['aroundStartedAt'] as int?,
            row['duration'] as int?,
            row['aroundDuration'] as int?,
            row['severity'] as int?,
            (row['favorite'] as int) != 0,
            row['hidden'] == null ? null : (row['hidden'] as int) != 0));
  }

  @override
  Stream<TaskTemplateVariantEntity?> findById(int id) {
    return _queryAdapter.queryStream(
        'SELECT * FROM TaskTemplateVariantEntity WHERE id = ?1',
        mapper: (Map<String, Object?> row) => TaskTemplateVariantEntity(
            row['id'] as int?,
            row['taskGroupId'] as int,
            row['taskTemplateId'] as int,
            row['title'] as String,
            row['description'] as String?,
            row['startedAt'] as int?,
            row['aroundStartedAt'] as int?,
            row['duration'] as int?,
            row['aroundDuration'] as int?,
            row['severity'] as int?,
            (row['favorite'] as int) != 0,
            row['hidden'] == null ? null : (row['hidden'] as int) != 0),
        arguments: [id],
        queryableName: 'TaskTemplateVariantEntity',
        isView: false);
  }

  @override
  Future<int> insertTaskTemplateVariant(
      TaskTemplateVariantEntity taskTemplateVariant) {
    return _taskTemplateVariantEntityInsertionAdapter.insertAndReturnId(
        taskTemplateVariant, OnConflictStrategy.abort);
  }

  @override
  Future<int> updateTaskTemplateVariant(
      TaskTemplateVariantEntity taskTemplateVariant) {
    return _taskTemplateVariantEntityUpdateAdapter.updateAndReturnChangedRows(
        taskTemplateVariant, OnConflictStrategy.abort);
  }

  @override
  Future<int> deleteTaskTemplateVariant(
      TaskTemplateVariantEntity taskTemplateVariant) {
    return _taskTemplateVariantEntityDeletionAdapter
        .deleteAndReturnChangedRows(taskTemplateVariant);
  }
}

class _$ScheduledTaskDao extends ScheduledTaskDao {
  _$ScheduledTaskDao(this.database, this.changeListener)
      : _queryAdapter = QueryAdapter(database, changeListener),
        _scheduledTaskEntityInsertionAdapter = InsertionAdapter(
            database,
            'ScheduledTaskEntity',
            (ScheduledTaskEntity item) => <String, Object?>{
                  'id': item.id,
                  'taskGroupId': item.taskGroupId,
                  'taskTemplateId': item.taskTemplateId,
                  'taskTemplateVariantId': item.taskTemplateVariantId,
                  'title': item.title,
                  'description': item.description,
                  'createdAt': item.createdAt,
                  'aroundStartAt': item.aroundStartAt,
                  'startAt': item.startAt,
                  'repetitionAfter': item.repetitionAfter,
                  'exactRepetitionAfter': item.exactRepetitionAfter,
                  'exactRepetitionAfterUnit': item.exactRepetitionAfterUnit,
                  'lastScheduledEventAt': item.lastScheduledEventAt,
                  'active': item.active ? 1 : 0
                },
            changeListener),
        _scheduledTaskEntityUpdateAdapter = UpdateAdapter(
            database,
            'ScheduledTaskEntity',
            ['id'],
            (ScheduledTaskEntity item) => <String, Object?>{
                  'id': item.id,
                  'taskGroupId': item.taskGroupId,
                  'taskTemplateId': item.taskTemplateId,
                  'taskTemplateVariantId': item.taskTemplateVariantId,
                  'title': item.title,
                  'description': item.description,
                  'createdAt': item.createdAt,
                  'aroundStartAt': item.aroundStartAt,
                  'startAt': item.startAt,
                  'repetitionAfter': item.repetitionAfter,
                  'exactRepetitionAfter': item.exactRepetitionAfter,
                  'exactRepetitionAfterUnit': item.exactRepetitionAfterUnit,
                  'lastScheduledEventAt': item.lastScheduledEventAt,
                  'active': item.active ? 1 : 0
                },
            changeListener),
        _scheduledTaskEntityDeletionAdapter = DeletionAdapter(
            database,
            'ScheduledTaskEntity',
            ['id'],
            (ScheduledTaskEntity item) => <String, Object?>{
                  'id': item.id,
                  'taskGroupId': item.taskGroupId,
                  'taskTemplateId': item.taskTemplateId,
                  'taskTemplateVariantId': item.taskTemplateVariantId,
                  'title': item.title,
                  'description': item.description,
                  'createdAt': item.createdAt,
                  'aroundStartAt': item.aroundStartAt,
                  'startAt': item.startAt,
                  'repetitionAfter': item.repetitionAfter,
                  'exactRepetitionAfter': item.exactRepetitionAfter,
                  'exactRepetitionAfterUnit': item.exactRepetitionAfterUnit,
                  'lastScheduledEventAt': item.lastScheduledEventAt,
                  'active': item.active ? 1 : 0
                },
            changeListener);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<ScheduledTaskEntity>
      _scheduledTaskEntityInsertionAdapter;

  final UpdateAdapter<ScheduledTaskEntity> _scheduledTaskEntityUpdateAdapter;

  final DeletionAdapter<ScheduledTaskEntity>
      _scheduledTaskEntityDeletionAdapter;

  @override
  Future<List<ScheduledTaskEntity>> findAll() async {
    return _queryAdapter.queryList(
        'SELECT * FROM ScheduledTaskEntity ORDER BY createdAt DESC, id DESC',
        mapper: (Map<String, Object?> row) => ScheduledTaskEntity(
            row['id'] as int?,
            row['taskGroupId'] as int,
            row['taskTemplateId'] as int?,
            row['taskTemplateVariantId'] as int?,
            row['title'] as String,
            row['description'] as String?,
            row['createdAt'] as int,
            row['aroundStartAt'] as int,
            row['startAt'] as int?,
            row['repetitionAfter'] as int,
            row['exactRepetitionAfter'] as int?,
            row['exactRepetitionAfterUnit'] as int?,
            row['lastScheduledEventAt'] as int?,
            (row['active'] as int) != 0));
  }

  @override
  Future<List<ScheduledTaskEntity>> findByTaskTemplateId(
      int taskTemplateId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM ScheduledTaskEntity WHERE taskTemplateId = ?1 ORDER BY createdAt DESC, id DESC',
        mapper: (Map<String, Object?> row) => ScheduledTaskEntity(row['id'] as int?, row['taskGroupId'] as int, row['taskTemplateId'] as int?, row['taskTemplateVariantId'] as int?, row['title'] as String, row['description'] as String?, row['createdAt'] as int, row['aroundStartAt'] as int, row['startAt'] as int?, row['repetitionAfter'] as int, row['exactRepetitionAfter'] as int?, row['exactRepetitionAfterUnit'] as int?, row['lastScheduledEventAt'] as int?, (row['active'] as int) != 0),
        arguments: [taskTemplateId]);
  }

  @override
  Future<List<ScheduledTaskEntity>> findByTaskTemplateVariantId(
      int taskTemplateVariantId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM ScheduledTaskEntity WHERE taskTemplateVariantId = ?1 ORDER BY createdAt DESC, id DESC',
        mapper: (Map<String, Object?> row) => ScheduledTaskEntity(row['id'] as int?, row['taskGroupId'] as int, row['taskTemplateId'] as int?, row['taskTemplateVariantId'] as int?, row['title'] as String, row['description'] as String?, row['createdAt'] as int, row['aroundStartAt'] as int, row['startAt'] as int?, row['repetitionAfter'] as int, row['exactRepetitionAfter'] as int?, row['exactRepetitionAfterUnit'] as int?, row['lastScheduledEventAt'] as int?, (row['active'] as int) != 0),
        arguments: [taskTemplateVariantId]);
  }

  @override
  Stream<ScheduledTaskEntity?> findById(int id) {
    return _queryAdapter.queryStream(
        'SELECT * FROM ScheduledTaskEntity WHERE id = ?1',
        mapper: (Map<String, Object?> row) => ScheduledTaskEntity(
            row['id'] as int?,
            row['taskGroupId'] as int,
            row['taskTemplateId'] as int?,
            row['taskTemplateVariantId'] as int?,
            row['title'] as String,
            row['description'] as String?,
            row['createdAt'] as int,
            row['aroundStartAt'] as int,
            row['startAt'] as int?,
            row['repetitionAfter'] as int,
            row['exactRepetitionAfter'] as int?,
            row['exactRepetitionAfterUnit'] as int?,
            row['lastScheduledEventAt'] as int?,
            (row['active'] as int) != 0),
        arguments: [id],
        queryableName: 'ScheduledTaskEntity',
        isView: false);
  }

  @override
  Future<int> insertScheduledTask(ScheduledTaskEntity scheduledTaskEntity) {
    return _scheduledTaskEntityInsertionAdapter.insertAndReturnId(
        scheduledTaskEntity, OnConflictStrategy.abort);
  }

  @override
  Future<int> updateScheduledTask(ScheduledTaskEntity scheduledTaskEntity) {
    return _scheduledTaskEntityUpdateAdapter.updateAndReturnChangedRows(
        scheduledTaskEntity, OnConflictStrategy.abort);
  }

  @override
  Future<int> deleteScheduledTask(ScheduledTaskEntity scheduledTaskEntity) {
    return _scheduledTaskEntityDeletionAdapter
        .deleteAndReturnChangedRows(scheduledTaskEntity);
  }
}

class _$ScheduledTaskEventDao extends ScheduledTaskEventDao {
  _$ScheduledTaskEventDao(this.database, this.changeListener)
      : _queryAdapter = QueryAdapter(database, changeListener),
        _scheduledTaskEventEntityInsertionAdapter = InsertionAdapter(
            database,
            'ScheduledTaskEventEntity',
            (ScheduledTaskEventEntity item) => <String, Object?>{
                  'id': item.id,
                  'taskEventId': item.taskEventId,
                  'scheduledTaskId': item.scheduledTaskId,
                  'createdAt': item.createdAt
                },
            changeListener),
        _scheduledTaskEventEntityUpdateAdapter = UpdateAdapter(
            database,
            'ScheduledTaskEventEntity',
            ['id'],
            (ScheduledTaskEventEntity item) => <String, Object?>{
                  'id': item.id,
                  'taskEventId': item.taskEventId,
                  'scheduledTaskId': item.scheduledTaskId,
                  'createdAt': item.createdAt
                },
            changeListener),
        _scheduledTaskEventEntityDeletionAdapter = DeletionAdapter(
            database,
            'ScheduledTaskEventEntity',
            ['id'],
            (ScheduledTaskEventEntity item) => <String, Object?>{
                  'id': item.id,
                  'taskEventId': item.taskEventId,
                  'scheduledTaskId': item.scheduledTaskId,
                  'createdAt': item.createdAt
                },
            changeListener);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<ScheduledTaskEventEntity>
      _scheduledTaskEventEntityInsertionAdapter;

  final UpdateAdapter<ScheduledTaskEventEntity>
      _scheduledTaskEventEntityUpdateAdapter;

  final DeletionAdapter<ScheduledTaskEventEntity>
      _scheduledTaskEventEntityDeletionAdapter;

  @override
  Future<List<ScheduledTaskEventEntity>> findByScheduledTaskId(
      int scheduledTaskId, int lastId, int limit) async {
    return _queryAdapter.queryList(
        'SELECT * FROM ScheduledTaskEventEntity WHERE scheduledTaskId = ?1 AND id < ?2 ORDER BY createdAt DESC, id DESC LIMIT ?3',
        mapper: (Map<String, Object?> row) => ScheduledTaskEventEntity(row['id'] as int?, row['taskEventId'] as int, row['scheduledTaskId'] as int, row['createdAt'] as int),
        arguments: [scheduledTaskId, lastId, limit]);
  }

  @override
  Future<List<ScheduledTaskEventEntity>> findByTaskEventId(
      int taskEventId, int lastId, int limit) async {
    return _queryAdapter.queryList(
        'SELECT * FROM ScheduledTaskEventEntity WHERE taskEventId = ?1 AND id < ?2 ORDER BY createdAt DESC, id DESC LIMIT ?3',
        mapper: (Map<String, Object?> row) => ScheduledTaskEventEntity(row['id'] as int?, row['taskEventId'] as int, row['scheduledTaskId'] as int, row['createdAt'] as int),
        arguments: [taskEventId, lastId, limit]);
  }

  @override
  Stream<ScheduledTaskEventEntity?> findById(int id) {
    return _queryAdapter.queryStream(
        'SELECT * FROM ScheduledTaskEventEntity WHERE id = ?1',
        mapper: (Map<String, Object?> row) => ScheduledTaskEventEntity(
            row['id'] as int?,
            row['taskEventId'] as int,
            row['scheduledTaskId'] as int,
            row['createdAt'] as int),
        arguments: [id],
        queryableName: 'ScheduledTaskEventEntity',
        isView: false);
  }

  @override
  Future<int> insertScheduledTaskEvent(
      ScheduledTaskEventEntity scheduledTaskEventEntity) {
    return _scheduledTaskEventEntityInsertionAdapter.insertAndReturnId(
        scheduledTaskEventEntity, OnConflictStrategy.abort);
  }

  @override
  Future<int> updateScheduledTaskEvent(
      ScheduledTaskEventEntity scheduledTaskEventEntity) {
    return _scheduledTaskEventEntityUpdateAdapter.updateAndReturnChangedRows(
        scheduledTaskEventEntity, OnConflictStrategy.abort);
  }

  @override
  Future<int> deleteScheduledTaskEvent(
      ScheduledTaskEventEntity scheduledTaskEventEntity) {
    return _scheduledTaskEventEntityDeletionAdapter
        .deleteAndReturnChangedRows(scheduledTaskEventEntity);
  }
}

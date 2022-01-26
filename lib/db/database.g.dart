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

  Future<sqflite.Database> open(String path, List<Migration> migrations,
      [Callback? callback]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 3,
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

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  TaskEventDao get taskEventDao {
    return _taskEventDaoInstance ??= _$TaskEventDao(database, changeListener);
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

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $AppDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $AppDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<AppDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
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

  TaskGroupDao? _taskGroupDaoInstance;

  TaskEventDao? _taskEventDaoInstance;

  TaskTemplateDao? _taskTemplateDaoInstance;

  TaskTemplateVariantDao? _taskTemplateVariantDaoInstance;

  ScheduledTaskDao? _scheduledTaskDaoInstance;

  ScheduledTaskFixedScheduleDao? _scheduledTaskFixedScheduleDaoInstance;

  ScheduledTaskEventDao? _scheduledTaskEventDaoInstance;

  SequencesDao? _sequencesDaoInstance;

  KeyValueDao? _keyValueDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 17,
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
            'CREATE TABLE IF NOT EXISTS `TaskGroupEntity` (`id` INTEGER, `name` TEXT NOT NULL, `colorRGB` INTEGER, `iconCodePoint` INTEGER, `iconFontFamily` TEXT, `iconFontPackage` TEXT, `hidden` INTEGER, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `TaskEventEntity` (`id` INTEGER, `taskGroupId` INTEGER, `originTaskTemplateId` INTEGER, `originTaskTemplateVariantId` INTEGER, `title` TEXT NOT NULL, `description` TEXT, `createdAt` INTEGER NOT NULL, `startedAt` INTEGER NOT NULL, `aroundStartedAt` INTEGER NOT NULL, `duration` INTEGER NOT NULL, `aroundDuration` INTEGER NOT NULL, `trackingFinishedAt` INTEGER, `severity` INTEGER NOT NULL, `favorite` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `TaskTemplateEntity` (`id` INTEGER, `taskGroupId` INTEGER NOT NULL, `title` TEXT NOT NULL, `description` TEXT, `startedAt` INTEGER, `aroundStartedAt` INTEGER, `duration` INTEGER, `aroundDuration` INTEGER, `severity` INTEGER, `favorite` INTEGER NOT NULL, `hidden` INTEGER, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `TaskTemplateVariantEntity` (`id` INTEGER, `taskGroupId` INTEGER NOT NULL, `taskTemplateId` INTEGER NOT NULL, `title` TEXT NOT NULL, `description` TEXT, `startedAt` INTEGER, `aroundStartedAt` INTEGER, `duration` INTEGER, `aroundDuration` INTEGER, `severity` INTEGER, `favorite` INTEGER NOT NULL, `hidden` INTEGER, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `ScheduledTaskEntity` (`id` INTEGER, `taskGroupId` INTEGER NOT NULL, `taskTemplateId` INTEGER, `taskTemplateVariantId` INTEGER, `title` TEXT NOT NULL, `description` TEXT, `createdAt` INTEGER NOT NULL, `aroundStartAt` INTEGER NOT NULL, `startAt` INTEGER, `repetitionAfter` INTEGER NOT NULL, `exactRepetitionAfter` INTEGER, `exactRepetitionAfterUnit` INTEGER, `lastScheduledEventAt` INTEGER, `oneTimeDueOn` INTEGER, `oneTimeCompletedOn` INTEGER, `active` INTEGER NOT NULL, `important` INTEGER, `pausedAt` INTEGER, `repetitionMode` INTEGER, `reminderNotificationEnabled` INTEGER, `reminderNotificationPeriod` INTEGER, `reminderNotificationUnit` INTEGER, `preNotificationEnabled` INTEGER, `preNotificationPeriod` INTEGER, `preNotificationUnit` INTEGER, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `ScheduledTaskFixedScheduleEntity` (`id` INTEGER, `scheduledTaskId` INTEGER NOT NULL, `type` INTEGER NOT NULL, `value` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `ScheduledTaskEventEntity` (`id` INTEGER, `taskEventId` INTEGER NOT NULL, `scheduledTaskId` INTEGER NOT NULL, `createdAt` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `SequencesEntity` (`id` INTEGER, `table` TEXT NOT NULL, `lastId` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `KeyValueEntity` (`id` INTEGER, `key` TEXT NOT NULL, `value` TEXT NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE INDEX `idx_TaskEventEntity_taskGroupId` ON `TaskEventEntity` (`taskGroupId`)');
        await database.execute(
            'CREATE INDEX `idx_TaskEventEntity_originTaskTemplateId` ON `TaskEventEntity` (`originTaskTemplateId`)');
        await database.execute(
            'CREATE INDEX `idx_TaskEventEntity_originTaskTemplateVariantId` ON `TaskEventEntity` (`originTaskTemplateVariantId`)');
        await database.execute(
            'CREATE INDEX `idx_ScheduledTaskFixedScheduleEntity_scheduledTaskId` ON `ScheduledTaskFixedScheduleEntity` (`scheduledTaskId`)');
        await database.execute(
            'CREATE INDEX `idx_ScheduledTaskEventEntity_taskEventId` ON `ScheduledTaskEventEntity` (`taskEventId`)');
        await database.execute(
            'CREATE INDEX `idx_ScheduledTaskEventEntity_scheduledTaskId` ON `ScheduledTaskEventEntity` (`scheduledTaskId`)');
        await database.execute(
            'CREATE UNIQUE INDEX `idx_KeyValue_key` ON `KeyValueEntity` (`key`)');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  TaskGroupDao get taskGroupDao {
    return _taskGroupDaoInstance ??= _$TaskGroupDao(database, changeListener);
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
  ScheduledTaskFixedScheduleDao get scheduledTaskFixedScheduleDao {
    return _scheduledTaskFixedScheduleDaoInstance ??=
        _$ScheduledTaskFixedScheduleDao(database, changeListener);
  }

  @override
  ScheduledTaskEventDao get scheduledTaskEventDao {
    return _scheduledTaskEventDaoInstance ??=
        _$ScheduledTaskEventDao(database, changeListener);
  }

  @override
  SequencesDao get sequencesDao {
    return _sequencesDaoInstance ??= _$SequencesDao(database, changeListener);
  }

  @override
  KeyValueDao get keyValueDao {
    return _keyValueDaoInstance ??= _$KeyValueDao(database, changeListener);
  }
}

class _$TaskGroupDao extends TaskGroupDao {
  _$TaskGroupDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database, changeListener),
        _taskGroupEntityInsertionAdapter = InsertionAdapter(
            database,
            'TaskGroupEntity',
            (TaskGroupEntity item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'colorRGB': item.colorRGB,
                  'iconCodePoint': item.iconCodePoint,
                  'iconFontFamily': item.iconFontFamily,
                  'iconFontPackage': item.iconFontPackage,
                  'hidden': item.hidden == null ? null : (item.hidden! ? 1 : 0)
                },
            changeListener),
        _taskGroupEntityUpdateAdapter = UpdateAdapter(
            database,
            'TaskGroupEntity',
            ['id'],
            (TaskGroupEntity item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'colorRGB': item.colorRGB,
                  'iconCodePoint': item.iconCodePoint,
                  'iconFontFamily': item.iconFontFamily,
                  'iconFontPackage': item.iconFontPackage,
                  'hidden': item.hidden == null ? null : (item.hidden! ? 1 : 0)
                },
            changeListener),
        _taskGroupEntityDeletionAdapter = DeletionAdapter(
            database,
            'TaskGroupEntity',
            ['id'],
            (TaskGroupEntity item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'colorRGB': item.colorRGB,
                  'iconCodePoint': item.iconCodePoint,
                  'iconFontFamily': item.iconFontFamily,
                  'iconFontPackage': item.iconFontPackage,
                  'hidden': item.hidden == null ? null : (item.hidden! ? 1 : 0)
                },
            changeListener);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<TaskGroupEntity> _taskGroupEntityInsertionAdapter;

  final UpdateAdapter<TaskGroupEntity> _taskGroupEntityUpdateAdapter;

  final DeletionAdapter<TaskGroupEntity> _taskGroupEntityDeletionAdapter;

  @override
  Future<List<TaskGroupEntity>> findAll() async {
    return _queryAdapter.queryList(
        'SELECT * FROM TaskGroupEntity ORDER BY id DESC',
        mapper: (Map<String, Object?> row) => TaskGroupEntity(
            row['id'] as int?,
            row['name'] as String,
            row['colorRGB'] as int?,
            row['iconCodePoint'] as int?,
            row['iconFontFamily'] as String?,
            row['iconFontPackage'] as String?,
            row['hidden'] == null ? null : (row['hidden'] as int) != 0));
  }

  @override
  Stream<TaskGroupEntity?> findById(int id) {
    return _queryAdapter.queryStream(
        'SELECT * FROM TaskGroupEntity WHERE id = ?1',
        mapper: (Map<String, Object?> row) => TaskGroupEntity(
            row['id'] as int?,
            row['name'] as String,
            row['colorRGB'] as int?,
            row['iconCodePoint'] as int?,
            row['iconFontFamily'] as String?,
            row['iconFontPackage'] as String?,
            row['hidden'] == null ? null : (row['hidden'] as int) != 0),
        arguments: [id],
        queryableName: 'TaskGroupEntity',
        isView: false);
  }

  @override
  Future<int> insertTaskGroup(TaskGroupEntity taskGroup) {
    return _taskGroupEntityInsertionAdapter.insertAndReturnId(
        taskGroup, OnConflictStrategy.abort);
  }

  @override
  Future<int> updateTaskGroup(TaskGroupEntity taskGroup) {
    return _taskGroupEntityUpdateAdapter.updateAndReturnChangedRows(
        taskGroup, OnConflictStrategy.abort);
  }

  @override
  Future<int> deleteTaskGroup(TaskGroupEntity taskGroup) {
    return _taskGroupEntityDeletionAdapter
        .deleteAndReturnChangedRows(taskGroup);
  }
}

class _$TaskEventDao extends TaskEventDao {
  _$TaskEventDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database, changeListener),
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
                  'trackingFinishedAt': item.trackingFinishedAt,
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
                  'trackingFinishedAt': item.trackingFinishedAt,
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
                  'trackingFinishedAt': item.trackingFinishedAt,
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
    int lastStartedAt,
    int lastId,
    int limit,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM TaskEventEntity WHERE startedAt <= ?1 AND id < ?2 ORDER BY startedAt DESC, id DESC LIMIT ?3',
        mapper: (Map<String, Object?> row) => TaskEventEntity(row['id'] as int?, row['taskGroupId'] as int?, row['originTaskTemplateId'] as int?, row['originTaskTemplateVariantId'] as int?, row['title'] as String, row['description'] as String?, row['createdAt'] as int, row['startedAt'] as int, row['aroundStartedAt'] as int, row['duration'] as int, row['aroundDuration'] as int, row['trackingFinishedAt'] as int?, row['severity'] as int, (row['favorite'] as int) != 0),
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
            row['trackingFinishedAt'] as int?,
            row['severity'] as int,
            (row['favorite'] as int) != 0),
        arguments: [id],
        queryableName: 'TaskEventEntity',
        isView: false);
  }

  @override
  Future<int?> count() async {
    return _queryAdapter.query('SELECT count(*) FROM TaskEventEntity',
        mapper: (Map<String, Object?> row) => row.values.first as int);
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
  _$TaskTemplateDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database, changeListener),
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
  _$TaskTemplateVariantDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database, changeListener),
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
  _$ScheduledTaskDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database, changeListener),
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
                  'oneTimeDueOn': item.oneTimeDueOn,
                  'oneTimeCompletedOn': item.oneTimeCompletedOn,
                  'active': item.active ? 1 : 0,
                  'important':
                      item.important == null ? null : (item.important! ? 1 : 0),
                  'pausedAt': item.pausedAt,
                  'repetitionMode': item.repetitionMode,
                  'reminderNotificationEnabled':
                      item.reminderNotificationEnabled == null
                          ? null
                          : (item.reminderNotificationEnabled! ? 1 : 0),
                  'reminderNotificationPeriod': item.reminderNotificationPeriod,
                  'reminderNotificationUnit': item.reminderNotificationUnit,
                  'preNotificationEnabled': item.preNotificationEnabled == null
                      ? null
                      : (item.preNotificationEnabled! ? 1 : 0),
                  'preNotificationPeriod': item.preNotificationPeriod,
                  'preNotificationUnit': item.preNotificationUnit
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
                  'oneTimeDueOn': item.oneTimeDueOn,
                  'oneTimeCompletedOn': item.oneTimeCompletedOn,
                  'active': item.active ? 1 : 0,
                  'important':
                      item.important == null ? null : (item.important! ? 1 : 0),
                  'pausedAt': item.pausedAt,
                  'repetitionMode': item.repetitionMode,
                  'reminderNotificationEnabled':
                      item.reminderNotificationEnabled == null
                          ? null
                          : (item.reminderNotificationEnabled! ? 1 : 0),
                  'reminderNotificationPeriod': item.reminderNotificationPeriod,
                  'reminderNotificationUnit': item.reminderNotificationUnit,
                  'preNotificationEnabled': item.preNotificationEnabled == null
                      ? null
                      : (item.preNotificationEnabled! ? 1 : 0),
                  'preNotificationPeriod': item.preNotificationPeriod,
                  'preNotificationUnit': item.preNotificationUnit
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
                  'oneTimeDueOn': item.oneTimeDueOn,
                  'oneTimeCompletedOn': item.oneTimeCompletedOn,
                  'active': item.active ? 1 : 0,
                  'important':
                      item.important == null ? null : (item.important! ? 1 : 0),
                  'pausedAt': item.pausedAt,
                  'repetitionMode': item.repetitionMode,
                  'reminderNotificationEnabled':
                      item.reminderNotificationEnabled == null
                          ? null
                          : (item.reminderNotificationEnabled! ? 1 : 0),
                  'reminderNotificationPeriod': item.reminderNotificationPeriod,
                  'reminderNotificationUnit': item.reminderNotificationUnit,
                  'preNotificationEnabled': item.preNotificationEnabled == null
                      ? null
                      : (item.preNotificationEnabled! ? 1 : 0),
                  'preNotificationPeriod': item.preNotificationPeriod,
                  'preNotificationUnit': item.preNotificationUnit
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
            row['oneTimeDueOn'] as int?,
            row['oneTimeCompletedOn'] as int?,
            (row['active'] as int) != 0,
            row['important'] == null ? null : (row['important'] as int) != 0,
            row['pausedAt'] as int?,
            row['repetitionMode'] as int?,
            row['reminderNotificationEnabled'] == null
                ? null
                : (row['reminderNotificationEnabled'] as int) != 0,
            row['reminderNotificationPeriod'] as int?,
            row['reminderNotificationUnit'] as int?,
            row['preNotificationEnabled'] == null
                ? null
                : (row['preNotificationEnabled'] as int) != 0,
            row['preNotificationPeriod'] as int?,
            row['preNotificationUnit'] as int?));
  }

  @override
  Future<List<ScheduledTaskEntity>> findByTaskTemplateId(
      int taskTemplateId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM ScheduledTaskEntity WHERE taskTemplateId = ?1 ORDER BY createdAt DESC, id DESC',
        mapper: (Map<String, Object?> row) => ScheduledTaskEntity(row['id'] as int?, row['taskGroupId'] as int, row['taskTemplateId'] as int?, row['taskTemplateVariantId'] as int?, row['title'] as String, row['description'] as String?, row['createdAt'] as int, row['aroundStartAt'] as int, row['startAt'] as int?, row['repetitionAfter'] as int, row['exactRepetitionAfter'] as int?, row['exactRepetitionAfterUnit'] as int?, row['lastScheduledEventAt'] as int?, row['oneTimeDueOn'] as int?, row['oneTimeCompletedOn'] as int?, (row['active'] as int) != 0, row['important'] == null ? null : (row['important'] as int) != 0, row['pausedAt'] as int?, row['repetitionMode'] as int?, row['reminderNotificationEnabled'] == null ? null : (row['reminderNotificationEnabled'] as int) != 0, row['reminderNotificationPeriod'] as int?, row['reminderNotificationUnit'] as int?, row['preNotificationEnabled'] == null ? null : (row['preNotificationEnabled'] as int) != 0, row['preNotificationPeriod'] as int?, row['preNotificationUnit'] as int?),
        arguments: [taskTemplateId]);
  }

  @override
  Future<List<ScheduledTaskEntity>> findByTaskTemplateVariantId(
      int taskTemplateVariantId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM ScheduledTaskEntity WHERE taskTemplateVariantId = ?1 ORDER BY createdAt DESC, id DESC',
        mapper: (Map<String, Object?> row) => ScheduledTaskEntity(row['id'] as int?, row['taskGroupId'] as int, row['taskTemplateId'] as int?, row['taskTemplateVariantId'] as int?, row['title'] as String, row['description'] as String?, row['createdAt'] as int, row['aroundStartAt'] as int, row['startAt'] as int?, row['repetitionAfter'] as int, row['exactRepetitionAfter'] as int?, row['exactRepetitionAfterUnit'] as int?, row['lastScheduledEventAt'] as int?, row['oneTimeDueOn'] as int?, row['oneTimeCompletedOn'] as int?, (row['active'] as int) != 0, row['important'] == null ? null : (row['important'] as int) != 0, row['pausedAt'] as int?, row['repetitionMode'] as int?, row['reminderNotificationEnabled'] == null ? null : (row['reminderNotificationEnabled'] as int) != 0, row['reminderNotificationPeriod'] as int?, row['reminderNotificationUnit'] as int?, row['preNotificationEnabled'] == null ? null : (row['preNotificationEnabled'] as int) != 0, row['preNotificationPeriod'] as int?, row['preNotificationUnit'] as int?),
        arguments: [taskTemplateVariantId]);
  }

  @override
  Stream<int?> countByTaskGroupId(int taskGroupId) {
    return _queryAdapter.queryStream(
        'SELECT count(*) FROM ScheduledTaskEntity WHERE taskGroupId = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [taskGroupId],
        queryableName: 'ScheduledTaskEntity',
        isView: false);
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
            row['oneTimeDueOn'] as int?,
            row['oneTimeCompletedOn'] as int?,
            (row['active'] as int) != 0,
            row['important'] == null ? null : (row['important'] as int) != 0,
            row['pausedAt'] as int?,
            row['repetitionMode'] as int?,
            row['reminderNotificationEnabled'] == null
                ? null
                : (row['reminderNotificationEnabled'] as int) != 0,
            row['reminderNotificationPeriod'] as int?,
            row['reminderNotificationUnit'] as int?,
            row['preNotificationEnabled'] == null
                ? null
                : (row['preNotificationEnabled'] as int) != 0,
            row['preNotificationPeriod'] as int?,
            row['preNotificationUnit'] as int?),
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

class _$ScheduledTaskFixedScheduleDao extends ScheduledTaskFixedScheduleDao {
  _$ScheduledTaskFixedScheduleDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _scheduledTaskFixedScheduleEntityInsertionAdapter = InsertionAdapter(
            database,
            'ScheduledTaskFixedScheduleEntity',
            (ScheduledTaskFixedScheduleEntity item) => <String, Object?>{
                  'id': item.id,
                  'scheduledTaskId': item.scheduledTaskId,
                  'type': item.type,
                  'value': item.value
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<ScheduledTaskFixedScheduleEntity>
      _scheduledTaskFixedScheduleEntityInsertionAdapter;

  @override
  Future<List<ScheduledTaskFixedScheduleEntity>> findByScheduledTaskId(
      int scheduledTaskId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM ScheduledTaskFixedScheduleEntity WHERE scheduledTaskId = ?1',
        mapper: (Map<String, Object?> row) => ScheduledTaskFixedScheduleEntity(row['id'] as int?, row['scheduledTaskId'] as int, row['type'] as int, row['value'] as int),
        arguments: [scheduledTaskId]);
  }

  @override
  Future<int?> deleteFixedScheduleByScheduledTaskId(int scheduledTaskId) async {
    return _queryAdapter.query(
        'DELETE FROM ScheduledTaskFixedScheduleEntity WHERE scheduledTaskId = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [scheduledTaskId]);
  }

  @override
  Future<int> insertFixedSchedule(
      ScheduledTaskFixedScheduleEntity scheduledTaskFixedScheduleEntity) {
    return _scheduledTaskFixedScheduleEntityInsertionAdapter.insertAndReturnId(
        scheduledTaskFixedScheduleEntity, OnConflictStrategy.abort);
  }
}

class _$ScheduledTaskEventDao extends ScheduledTaskEventDao {
  _$ScheduledTaskEventDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database, changeListener),
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
    int scheduledTaskId,
    int lastId,
    int limit,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM ScheduledTaskEventEntity WHERE scheduledTaskId = ?1 AND id < ?2 ORDER BY createdAt DESC, id DESC LIMIT ?3',
        mapper: (Map<String, Object?> row) => ScheduledTaskEventEntity(row['id'] as int?, row['taskEventId'] as int, row['scheduledTaskId'] as int, row['createdAt'] as int),
        arguments: [scheduledTaskId, lastId, limit]);
  }

  @override
  Future<List<ScheduledTaskEventEntity>> findByTaskEventId(
      int taskEventId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM ScheduledTaskEventEntity WHERE taskEventId = ?1 ORDER BY createdAt DESC LIMIT 10',
        mapper: (Map<String, Object?> row) => ScheduledTaskEventEntity(row['id'] as int?, row['taskEventId'] as int, row['scheduledTaskId'] as int, row['createdAt'] as int),
        arguments: [taskEventId]);
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

class _$SequencesDao extends SequencesDao {
  _$SequencesDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database, changeListener),
        _sequencesEntityInsertionAdapter = InsertionAdapter(
            database,
            'SequencesEntity',
            (SequencesEntity item) => <String, Object?>{
                  'id': item.id,
                  'table': item.table,
                  'lastId': item.lastId
                },
            changeListener),
        _sequencesEntityUpdateAdapter = UpdateAdapter(
            database,
            'SequencesEntity',
            ['id'],
            (SequencesEntity item) => <String, Object?>{
                  'id': item.id,
                  'table': item.table,
                  'lastId': item.lastId
                },
            changeListener);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<SequencesEntity> _sequencesEntityInsertionAdapter;

  final UpdateAdapter<SequencesEntity> _sequencesEntityUpdateAdapter;

  @override
  Stream<SequencesEntity?> findByTable(String table) {
    return _queryAdapter.queryStream(
        'SELECT * FROM SequencesEntity WHERE `table` = ?1',
        mapper: (Map<String, Object?> row) => SequencesEntity(
            row['id'] as int?, row['table'] as String, row['lastId'] as int),
        arguments: [table],
        queryableName: 'SequencesEntity',
        isView: false);
  }

  @override
  Future<int> insertSequence(SequencesEntity sequence) {
    return _sequencesEntityInsertionAdapter.insertAndReturnId(
        sequence, OnConflictStrategy.abort);
  }

  @override
  Future<int> updateSequence(SequencesEntity sequence) {
    return _sequencesEntityUpdateAdapter.updateAndReturnChangedRows(
        sequence, OnConflictStrategy.abort);
  }
}

class _$KeyValueDao extends KeyValueDao {
  _$KeyValueDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database, changeListener),
        _keyValueEntityInsertionAdapter = InsertionAdapter(
            database,
            'KeyValueEntity',
            (KeyValueEntity item) => <String, Object?>{
                  'id': item.id,
                  'key': item.key,
                  'value': item.value
                },
            changeListener),
        _keyValueEntityUpdateAdapter = UpdateAdapter(
            database,
            'KeyValueEntity',
            ['id'],
            (KeyValueEntity item) => <String, Object?>{
                  'id': item.id,
                  'key': item.key,
                  'value': item.value
                },
            changeListener),
        _keyValueEntityDeletionAdapter = DeletionAdapter(
            database,
            'KeyValueEntity',
            ['id'],
            (KeyValueEntity item) => <String, Object?>{
                  'id': item.id,
                  'key': item.key,
                  'value': item.value
                },
            changeListener);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<KeyValueEntity> _keyValueEntityInsertionAdapter;

  final UpdateAdapter<KeyValueEntity> _keyValueEntityUpdateAdapter;

  final DeletionAdapter<KeyValueEntity> _keyValueEntityDeletionAdapter;

  @override
  Stream<KeyValueEntity?> findById(int id) {
    return _queryAdapter.queryStream(
        'SELECT * FROM KeyValueEntity WHERE id = ?1',
        mapper: (Map<String, Object?> row) => KeyValueEntity(
            row['id'] as int?, row['key'] as String, row['value'] as String),
        arguments: [id],
        queryableName: 'KeyValueEntity',
        isView: false);
  }

  @override
  Stream<KeyValueEntity?> findByKey(String key) {
    return _queryAdapter.queryStream(
        'SELECT * FROM KeyValueEntity WHERE `key` = ?1',
        mapper: (Map<String, Object?> row) => KeyValueEntity(
            row['id'] as int?, row['key'] as String, row['value'] as String),
        arguments: [key],
        queryableName: 'KeyValueEntity',
        isView: false);
  }

  @override
  Future<List<KeyValueEntity>> findAll() async {
    return _queryAdapter.queryList(
        'SELECT * FROM KeyValueEntity ORDER BY key, id',
        mapper: (Map<String, Object?> row) => KeyValueEntity(
            row['id'] as int?, row['key'] as String, row['value'] as String));
  }

  @override
  Future<int> insertKeyValue(KeyValueEntity entity) {
    return _keyValueEntityInsertionAdapter.insertAndReturnId(
        entity, OnConflictStrategy.abort);
  }

  @override
  Future<int> updateKeyValue(KeyValueEntity entity) {
    return _keyValueEntityUpdateAdapter.updateAndReturnChangedRows(
        entity, OnConflictStrategy.abort);
  }

  @override
  Future<int> deleteKeyValue(KeyValueEntity entity) {
    return _keyValueEntityDeletionAdapter.deleteAndReturnChangedRows(entity);
  }
}

class TaskGroup {
  int? id;
  String name;
  String? description;
  int? colorRGB;
  int? taskGroupId;

  TaskGroup({this.id, required this.name, this.description, this.colorRGB, this.taskGroupId});

}


// mockup methods
List<TaskGroup> testGroups = [
  TaskGroup(id: -1, name: "Household"),
  TaskGroup(id: -3, name: "Cooking", taskGroupId: -1),
  TaskGroup(id: -4, name: "Cleaning", taskGroupId: -1),
  TaskGroup(id: -2, name: "Kid"),
];

const _pathSeparator = " / ";

String getTaskGroupPathAsString(int taskGroupId) {
  StringBuffer sb = StringBuffer();
  _buildTaskGroupPathAsString(taskGroupId, sb);
  final s = sb.toString();
  return s.substring(0, s.length - _pathSeparator.length);
}

_buildTaskGroupPathAsString(int taskGroupId, StringBuffer sb) {
  final group = findTaskGroupById(taskGroupId);
  if (group.taskGroupId != null) {
    _buildTaskGroupPathAsString(group.taskGroupId!, sb);
  }
  sb..write(group.name)..write(_pathSeparator);
}

TaskGroup findTaskGroupById(int id) => testGroups.firstWhere((element) => element.id == id);



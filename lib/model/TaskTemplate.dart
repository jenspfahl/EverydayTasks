import 'package:flutter/material.dart';
import 'When.dart';

class TaskTemplate {
  final int? id;
  final int? taskGroupId;

  final String name;
  final String description;
  final When? when;
  final TimeOfDay? whenExactly;
  final Duration? duration;
  final int? durationExactlyMinutes;
  final bool favorite;

  TaskTemplate(this.id, this.taskGroupId,
      this.name, this.description, this.when, this.whenExactly,
      this.duration, this.durationExactlyMinutes, this.favorite);
}
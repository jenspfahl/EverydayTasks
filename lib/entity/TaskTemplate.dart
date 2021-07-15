import 'package:floor/floor.dart';
import 'package:flutter/material.dart';
import 'When.dart';

@entity
class TaskTemplate {
  @primaryKey
  final int id;

  final String name;
  final String description;
  final int? colorRGB;
  final When? when;
  final TimeOfDay? whenExactly;
  final Duration? duration;
  final int? durationExactlyMinutes;
  final int? taskGroupId;

  TaskTemplate(this.id, this.name, this.description, this.colorRGB, this.when, this.whenExactly,
      this.duration, this.durationExactlyMinutes, this.taskGroupId);
}
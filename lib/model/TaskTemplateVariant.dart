import 'package:flutter/material.dart';
import 'Severity.dart';
import 'When.dart';

class TaskTemplateVariant {
  final int? id;
  final int taskTemplateId;

  final String name;
  final String description;
  final When? when;
  final TimeOfDay? whenExactly;
  final Duration? duration;
  final int? durationExactlyMinutes;
  final Severity? severity;
  final bool favorite;

  TaskTemplateVariant(this.id, this.taskTemplateId,
      this.name, this.description, this.when, this.whenExactly,
      this.duration, this.durationExactlyMinutes, this.severity, this.favorite);
}
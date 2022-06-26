import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';

enum Severity {EASY, MEDIUM, HARD}


Widget severityToIcon(Severity severity, [Color? iconColor]) {
  List<Icon> icons = List.generate(
      severity.index + 1, (index) => Icon(
        Icons.fitness_center_rounded,
        color: iconColor,
      ));

  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: icons,
  );
}

String severityToString(Severity severity) {
  switch (severity) {
    case Severity.EASY: return translate('model.severity.easy');
    case Severity.MEDIUM: return translate('model.severity.medium');
    case Severity.HARD: return translate('model.severity.hard');
  }
}
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
    case Severity.EASY: return "Easy going";
    case Severity.MEDIUM: return "As always";
    case Severity.HARD: return "Exhausting";
  }
}
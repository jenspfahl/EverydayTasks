import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:personaltasklogger/model/Severity.dart';

Widget severityToIcon(Severity severity) {
  List<Icon> icons = List.generate(
      severity.index + 1, (index) => Icon(Icons.fitness_center_rounded));

  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: icons,
  );
}
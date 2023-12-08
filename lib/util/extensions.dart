import 'dart:ffi';

import 'package:flutter/material.dart';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

extension DoubleExtension on double {
  double min(double minValue) {
    if (this < minValue) return minValue;
    else return this;
  }  
  double max(double maxValue) {
    if (this > maxValue) return maxValue;
    else return this;
  }
}

extension DurationExtension on Duration {
  Duration min(Duration minValue) {
    if (this.inSeconds < minValue.inSeconds) return minValue;
    else return this;
  }
  Duration max(Duration maxValue) {
    if (this.inSeconds > maxValue.inSeconds) return maxValue;
    else return this;
  }
}

extension ListExtension<E> on List<E> {
  List<E> append(E elem) {
    this.add(elem);
    return this;
  }

  List<E> appendAll(List<E> elems) {
    this.addAll(elems);
    return this;
  }
}

extension TimeOfDayExtension on TimeOfDay {

  double toDouble() => this.hour + this.minute/60.0;

}
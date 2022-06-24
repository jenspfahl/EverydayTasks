

import 'package:flutter_translate/flutter_translate.dart';

abstract class Unit {
  num value;

  Unit(this.value);

  String getSubKey();

  String getUnitAsString(num value) {
    return translatePlural('common.units.${getSubKey()}', value);
  }

  String toStringWithAdjective(String adjective) {
    final unit = getUnitAsString(value);
    return "$value $adjective $unit";
  }

  @override
  String toString() {
    final unit = getUnitAsString(value);
    return "$value $unit";
  }

}

class Years extends Unit {

  Years(num value) : super(value);

  @override
  String getSubKey() {
    return "year";
  }
}
class Months extends Unit {

  Months(num value) : super(value);

  @override
  String getSubKey() {
    return "month";
  }
}

class Weeks extends Unit {

  Weeks(num value) : super(value);

  @override
  String getSubKey() {
    return "week";
  }

}

class Days extends Unit {

  Days(num value) : super(value);

  @override
  String getSubKey() {
    return "day";
  }

}

class Hours extends Unit {

  Hours(num value) : super(value);

  @override
  String getSubKey() {
    return "hour";
  }

}

class Minutes extends Unit {

  Minutes(num value) : super(value);

  @override
  String getSubKey() {
    return "minute";
  }

}

class Seconds extends Unit {

  Seconds(num value) : super(value);

  @override
  String getSubKey() {
    return "second";
  }

}

class Items extends Unit {

  Items(num value) : super(value);

  @override
  String getSubKey() {
    return "item";
  }

}

class Schedules extends Unit {

  Schedules(num value) : super(value);

  @override
  String getSubKey() {
    return "schedule";
  }

}
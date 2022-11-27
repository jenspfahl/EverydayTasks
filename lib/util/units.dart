import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';

import 'i18n.dart';

enum Clause {dative}


Clause? usedClause(BuildContext context, Clause clause) {
  final locale = currentLocale(context);
  // debugPrint("locale $locale for clause $clause");
  if (locale.languageCode == 'de') {
    return clause;
  }
  return null;
}

abstract class Unit {
  num value;
  Clause? clause;

  Unit(this.value, [this.clause]);

  String getSubKey();

  String getUnitAsString(num value) {
    var key = 'common.units.${getSubKey()}';

    if (clause != null) {
      final clauseName = clause.toString().split('.').last;
      key = '${key}_$clauseName';
    }
    debugPrint("key=$key");
    return translatePlural(key, value);
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

  Years(num value, [Clause? clause]) : super(value, clause);

  @override
  String getSubKey() {
    return "year";
  }
}
class Months extends Unit {

  Months(num value, [Clause? clause]) : super(value, clause);

  @override
  String getSubKey() {
    return "month";
  }
}

class Weeks extends Unit {

  Weeks(num value, [Clause? clause]) : super(value, clause);

  @override
  String getSubKey() {
    return "week";
  }

}

class Days extends Unit {

  Days(num value, [Clause? clause]) : super(value, clause);

  @override
  String getSubKey() {
    return "day";
  }

}

class Hours extends Unit {

  Hours(num value, [Clause? clause]) : super(value, clause);

  @override
  String getSubKey() {
    return "hour";
  }

}

class Minutes extends Unit {

  Minutes(num value, [Clause? clause]) : super(value, clause);

  @override
  String getSubKey() {
    return "minute";
  }

}

class Seconds extends Unit {

  Seconds(num value, [Clause? clause]) : super(value, clause);

  @override
  String getSubKey() {
    return "second";
  }

}

class Items extends Unit {

  Items(num value, [Clause? clause]) : super(value, clause);

  @override
  String getSubKey() {
    return "item";
  }

}

class Schedules extends Unit {

  Schedules(num value, [Clause? clause]) : super(value, clause);

  @override
  String getSubKey() {
    return "schedule";
  }

}
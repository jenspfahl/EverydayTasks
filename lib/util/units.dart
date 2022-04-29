

abstract class Unit {
  num value;

  Unit(this.value);
  String getSingleUnitAsString();
  String getPluralUnitAsString();

  String toStringWithAdjective(String adjective) {
    final unit = value == 1 ? getSingleUnitAsString() : getPluralUnitAsString();
    return "$value $adjective $unit";
  }

  @override
  String toString() {
    final unit = value == 1 ? getSingleUnitAsString() : getPluralUnitAsString();
    return "$value $unit";
  }

}

class Months extends Unit {

  Months(num value) : super(value);

  @override
  String getSingleUnitAsString() {
    return "month";
  }

  @override
  String getPluralUnitAsString() {
    return "months";
  }
}

class Weeks extends Unit {

  Weeks(num value) : super(value);

  @override
  String getSingleUnitAsString() {
    return "week";
  }

  @override
  String getPluralUnitAsString() {
    return "weeks";
  }
}

class Days extends Unit {

  Days(num value) : super(value);

  @override
  String getSingleUnitAsString() {
    return "day";
  }

  @override
  String getPluralUnitAsString() {
    return "days";
  }
}

class Hours extends Unit {

  Hours(num value) : super(value);

  @override
  String getSingleUnitAsString() {
    return "hour";
  }

  @override
  String getPluralUnitAsString() {
    return "hours";
  }
}

class Minutes extends Unit {

  Minutes(num value) : super(value);

  @override
  String getSingleUnitAsString() {
    return "minute";
  }

  @override
  String getPluralUnitAsString() {
    return "minutes";
  }
}

class Items extends Unit {

  Items(num value) : super(value);

  @override
  String getSingleUnitAsString() {
    return "item";
  }

  @override
  String getPluralUnitAsString() {
    return "items";
  }
}

class Schedules extends Unit {

  Schedules(num value) : super(value);

  @override
  String getSingleUnitAsString() {
    return "schedule";
  }

  @override
  String getPluralUnitAsString() {
    return "schedules";
  }
}
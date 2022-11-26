import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:numberpicker/numberpicker.dart';

import 'package:personaltasklogger/model/Schedule.dart';
import 'package:personaltasklogger/ui/PersonalTaskLoggerApp.dart';
import 'package:personaltasklogger/ui/DynamicPicker.dart';
import 'package:personaltasklogger/ui/utils.dart';
import 'package:personaltasklogger/util/extensions.dart';

class RepetitionPicker extends StatefulWidget {

  late final CustomRepetition _initialRepetition;
  final String description;
  final ValueChanged<CustomRepetition> onChanged;
  final List<RepetitionUnit> supportedUnits;

  RepetitionPicker({
    CustomRepetition? initialRepetition,
    required this.description,
    required this.onChanged,
    required this.supportedUnits
  }) {
    this._initialRepetition = initialRepetition != null
        ? CustomRepetition(initialRepetition.repetitionValue, initialRepetition.repetitionUnit)
        : createDefaultRepetition();
  }
  
  @override
  _RepetitionPickerState createState() {
    return _RepetitionPickerState();
  }

  static CustomRepetition createDefaultRepetition() => CustomRepetition(1, RepetitionUnit.DAYS);

}

class _RepetitionPickerState extends State<RepetitionPicker> {
  late CustomRepetition _customRepetition;

  @override
  void initState() {
    super.initState();

    _customRepetition = widget._initialRepetition;
  }

  @override
  Widget build(BuildContext context) {
    final valuePicker = NumberPicker(
      value: _customRepetition.repetitionValue,
      minValue: 1, //TODO control from outside
      maxValue: 1000, //TODO control this from outside
      textStyle: isDarkMode(context)
        ? TextStyle(color: Colors.grey, fontSize: 14)
        : null,
      selectedTextStyle: isDarkMode(context)
        ? TextStyle(color: PRIMARY_COLOR, fontSize: 24)
        : null,
      onChanged: (value) => setState(() { 
        _customRepetition.repetitionValue = value;
        widget.onChanged(_customRepetition);
      }),
    );

    final unitPicker = DynamicPicker<RepetitionUnit>(
      value: _customRepetition.repetitionUnit,
      values: widget.supportedUnits,
      textMapper: (unit) => Schedule.fromRepetitionUnitToString(unit),
      textStyle: isDarkMode(context)
          ? TextStyle(color: Colors.grey, fontSize: 14)
          : null,
      selectedTextStyle: isDarkMode(context)
          ? TextStyle(color: PRIMARY_COLOR, fontSize: 24)
          : null,
      onChanged: (value) => setState(() {
        _customRepetition.repetitionUnit = value;
        widget.onChanged(_customRepetition);
      }),
    );

    //scaffold the full homepage
    return Column(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(widget.description),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(translate('common.words.value').capitalize(), style: TextStyle(fontSize: 18)),
              Text(translate('common.words.unit').capitalize(), style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
        Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: valuePicker,
            ),
            Expanded(
              child: unitPicker,
            ),
          ],
        ),
      ],
    );
  }
}
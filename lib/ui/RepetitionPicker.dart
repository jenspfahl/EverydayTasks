import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:numberpicker/numberpicker.dart';

import 'package:personaltasklogger/model/Schedule.dart';
import 'package:personaltasklogger/util/extensions.dart';

class RepetitionPicker extends StatefulWidget {

  late final CustomRepetition _initialRepetition;
  final ValueChanged<CustomRepetition> onChanged;

  RepetitionPicker({
    CustomRepetition? initialRepetition,
    required this.onChanged
  }) {
    this._initialRepetition = initialRepetition ?? createDefaultRepetition();
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
    final valuePicker = new NumberPicker(
      value: _customRepetition.repetitionValue,
      minValue: 1, //TODO control from outside
      maxValue: 10000, //TODO control this from outside
      onChanged: (value) => setState(() { 
        _customRepetition.repetitionValue = value;
        widget.onChanged(_customRepetition);
      }),
    );

    final unitChildren = RepetitionUnit.values.map((unit) {
      return RadioListTile<RepetitionUnit>(
        dense: true,
        visualDensity: VisualDensity(horizontal: 0, vertical: -4),
        title: Text(Schedule.fromRepetitionUnitToString(unit)),
        value: unit,
        groupValue: _customRepetition.repetitionUnit ,
        onChanged: (RepetitionUnit? value) {
          setState(() {
            if (value != null) {
              _customRepetition.repetitionUnit = value;
              widget.onChanged(_customRepetition);
            }
          });
        }
      );
    }).toList();

    //scaffold the full homepage
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(translate('common.words.value').capitalize()),
            Text(translate('common.words.unit').capitalize()),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: valuePicker,
            ),
            Expanded(
              child: Column(
                children: unitChildren,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:numberpicker/numberpicker.dart';

import 'package:personaltasklogger/model/Schedule.dart';
import 'package:personaltasklogger/util/extensions.dart';

class RepetitionPicker extends StatefulWidget {

  static final DEFAULT_INIT_REPETITION = CustomRepetition(1, RepetitionUnit.DAYS);

  late final CustomRepetition _initialRepetition;
  final ValueChanged<CustomRepetition> onChanged;

  RepetitionPicker({
    CustomRepetition? initialRepetition,
    required this.onChanged
  }) {
    this._initialRepetition = initialRepetition ?? DEFAULT_INIT_REPETITION;
  }
  
  @override
  _RepetitionPickerState createState() {
    return _RepetitionPickerState();
  }

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
    final unitDropDown = new DropdownButton<RepetitionUnit>( //TODO use a Picker instead
      value: _customRepetition.repetitionUnit,
      items: RepetitionUnit.values.map((RepetitionUnit unit) {
        return DropdownMenuItem(
          value: unit,
          child: Text(Schedule.fromRepetitionUnitToString(unit)),
        );
      }).toList(),
      onChanged: (value) => setState(() { 
        if (value != null) {
          _customRepetition.repetitionUnit = value;
          widget.onChanged(_customRepetition);
        }
      }),
    );
    //scaffold the full homepage
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Column(
          children: [
            Text(translate('common.words.value').capitalize()),
            valuePicker
          ],
        ),
        Column(
          children: [
            Text(translate('common.words.unit').capitalize()),
            unitDropDown,
          ],
        ),
      ],
    );
  }
}
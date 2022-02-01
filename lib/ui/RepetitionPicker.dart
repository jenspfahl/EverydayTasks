import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';

import 'package:personaltasklogger/model/Schedule.dart';

class RepetitionPicker extends StatefulWidget {
  late final CustomRepetition _initialRepetition;
  final Function(CustomRepetition) _selectedRepetition;

  RepetitionPicker(CustomRepetition? initialRepetition, this._selectedRepetition) {
    this._initialRepetition = initialRepetition ?? CustomRepetition(1, RepetitionUnit.DAYS);
  }
  
  @override
  _RepetitionPickerState createState() {
    return _RepetitionPickerState(_initialRepetition, _selectedRepetition);
  }

}

class _RepetitionPickerState extends State<RepetitionPicker> {
  late final CustomRepetition _customRepetition;
  final Function(CustomRepetition) _onSelected;

  late NumberPicker _valuePicker;
  late DropdownButton<RepetitionUnit> _unitDropDown; //TODO use kind of array picker

  _RepetitionPickerState(this._customRepetition, this._onSelected);
  
  @override
  Widget build(BuildContext context) {
    _valuePicker = new NumberPicker(
      value: _customRepetition.repetitionValue,
      minValue: 1, //TODO control from outside
      maxValue: 10000, //TODO control this from outside
      onChanged: (value) => setState(() { 
        _customRepetition.repetitionValue = value;
        _onSelected(_customRepetition);
      }),
    );
    _unitDropDown = new DropdownButton<RepetitionUnit>(
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
          _onSelected(_customRepetition);
        }
      }),
    );
    //scaffold the full homepage
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Column(
          children: [
            Text("Value"),
            _valuePicker
          ],
        ),
        Column(
          children: [
            Text("Unit"),
            _unitDropDown,
          ],
        ),
      ],
    );
  }
}
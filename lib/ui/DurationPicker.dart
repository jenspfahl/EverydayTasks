import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';

class DurationPicker extends StatefulWidget {
  int _currentHours;
  int _currentMinutes;

  _DurationPickerState? _stateRef;

  DurationPicker(this._currentHours, this._currentMinutes);
  
  @override
  _DurationPickerState createState() {
    final state = _DurationPickerState(_currentHours, _currentMinutes);
    _stateRef = state;
    return state;
  }

  Duration? getSelectedDuration() {
    final hours = _stateRef?._currentHours;
    final minutes = _stateRef?._currentMinutes;

    if (hours != null && minutes != null) {
      return Duration(hours: hours, minutes: minutes);
    }
    return null;
  }

}

class _DurationPickerState extends State<DurationPicker> {
  int _currentHours;
  int _currentMinutes;
  late NumberPicker _hoursPicker;
  late NumberPicker _minutesPicker;

  _DurationPickerState(this._currentHours, this._currentMinutes);
  
  @override
  Widget build(BuildContext context) {
    _hoursPicker = new NumberPicker(
      value: _currentHours,
      minValue: 0,
      maxValue: 23,
      onChanged: (value) => setState(() => _currentHours = value),
    );
    _minutesPicker = new NumberPicker(
      value: _currentMinutes,
      minValue: 0,
      maxValue: 59,
      onChanged: (value) => setState(() => _currentMinutes = value),
    );
    //scaffold the full homepage
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Column(
          children: [
            Text("Hours"),
            _hoursPicker
          ],
        ),
        Column(
          children: [
            Text("Minutes"),
            _minutesPicker,
          ],
        ),
      ],
    );
  }
}
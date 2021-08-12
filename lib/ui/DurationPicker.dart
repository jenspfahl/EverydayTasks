import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';

class DurationPicker extends StatefulWidget {
  late final int _initialHours;
  late final int _initialMinutes;
  final Function(Duration) _selectedDuration;

  DurationPicker(Duration? initialDuration, this._selectedDuration) {
    this._initialHours = initialDuration?.inHours ?? 0;
    this._initialMinutes = (initialDuration?.inMinutes ?? 0) % 60;
  }
  
  @override
  _DurationPickerState createState() {
    return _DurationPickerState(_initialHours, _initialMinutes, _selectedDuration);
  }

}

class _DurationPickerState extends State<DurationPicker> {
  int _initialHours;
  int _initialMinutes;
  final Function(Duration) _selectedDuration;

  late NumberPicker _hoursPicker;
  late NumberPicker _minutesPicker;

  _DurationPickerState(this._initialHours, this._initialMinutes, this._selectedDuration);
  
  @override
  Widget build(BuildContext context) {
    _hoursPicker = new NumberPicker(
      value: _initialHours,
      minValue: 0,
      maxValue: 10, //TODO control this from outside
      onChanged: (value) => setState(() { 
        _initialHours = value;
        _selectedDuration(_getSelectedDuration());
      }),
    );
    _minutesPicker = new NumberPicker(
      value: _initialMinutes,
      minValue: 0,
      maxValue: 59,
      onChanged: (value) => setState(() { 
        _initialMinutes = value;
        _selectedDuration(_getSelectedDuration());
      }),
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

  Duration _getSelectedDuration() {
      return Duration(hours: _initialHours, minutes: _initialMinutes);
  }
}
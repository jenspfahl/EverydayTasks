import 'package:flutter/material.dart';
import 'package:personaltasklogger/model/Severity.dart';
import 'package:personaltasklogger/ui/utils.dart';

class SeverityPicker extends StatefulWidget {
  late final Severity? _initialSeverity;
  final bool showText;
  final double singleButtonWidth;
  final Function(Severity)? _selectedSeverityHandler;

  SeverityPicker(this._initialSeverity, this._selectedSeverityHandler,
      {required this.showText, required this.singleButtonWidth});
  
  @override
  _SeverityPickerState createState() {
    return _SeverityPickerState();
  }

}

class _SeverityPickerState extends State<SeverityPicker> {
  late List<bool> _severitySelection;
  int? _severityIndex;

  @override
  Widget build(BuildContext context) {
    _severityIndex = widget._initialSeverity?.index;
    _severitySelection = List.generate(Severity.values.length, (index) => index == _severityIndex);

    return ToggleButtons(
      borderRadius: BorderRadius.all(Radius.circular(5.0)),
      renderBorder: true,
      borderWidth: 1.5,
      borderColor: Colors.grey,
      color: Colors.grey.shade600,
      selectedBorderColor: Colors.blue,
      children: [
        SizedBox(
          width: widget.singleButtonWidth,
          child: (widget.showText)
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    severityToIcon(Severity.EASY),
                    Text(severityToString(Severity.EASY), textAlign: TextAlign.center,),
                  ],
                )
              : severityToIcon(Severity.EASY),
        ),
        SizedBox(
          width: widget.singleButtonWidth,
          child: (widget.showText)
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    severityToIcon(Severity.MEDIUM),
                    Text(severityToString(Severity.MEDIUM), textAlign: TextAlign.center,),
                  ],
                )
              : severityToIcon(Severity.MEDIUM),
        ),
        SizedBox(
          width: widget.singleButtonWidth,
          child: (widget.showText)
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    severityToIcon(Severity.HARD),
                    Text(severityToString(Severity.HARD), textAlign: TextAlign.center,),
                  ],
                )
              : severityToIcon(Severity.HARD),
        ),
      ],
      isSelected: _severitySelection,
      onPressed: (int index) {
        FocusScope.of(context).unfocus();
        setState(() {
          if (_severityIndex != null) {
            _severitySelection[_severityIndex!] = false;
          }
          _severitySelection[index] = true;
          _severityIndex = index;
          if (widget._selectedSeverityHandler != null) {
            widget._selectedSeverityHandler!(Severity.values.elementAt(index));
          }
        });
      },
    );
  }

}
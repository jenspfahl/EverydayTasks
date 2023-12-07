import 'package:flutter/material.dart';
import 'package:personaltasklogger/model/Severity.dart';
import 'package:personaltasklogger/ui/utils.dart';

import '../PersonalTaskLoggerApp.dart';

class SeverityPicker extends StatefulWidget {
  final bool showText;
  final double singleButtonWidth;
  final Severity? initialSeverity;
  final ValueChanged<Severity> onChanged;

  const SeverityPicker({
    Key? key,
    required this.showText,
    required this.singleButtonWidth,
    this.initialSeverity, 
    required this.onChanged,
  });
  
  @override
  _SeverityPickerState createState() => _SeverityPickerState();

}

class _SeverityPickerState extends State<SeverityPicker> {
  late List<bool> _severitySelection;
  int? _severityIndex;

  @override
  void initState() {
    super.initState();
    _initState();
  }

  @override
  void didUpdateWidget(covariant SeverityPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    _initState();
  }

  void _initState() {
    _severityIndex = widget.initialSeverity?.index;
    _severitySelection = List.generate(Severity.values.length, (index) => index == _severityIndex);
  }

  @override
  Widget build(BuildContext context) {

    return ToggleButtons(
      borderRadius: BorderRadius.all(Radius.circular(5.0)),
      renderBorder: true,
      borderWidth: 1.5,
      borderColor: Colors.grey,
      color: Colors.grey.shade600,
      selectedBorderColor: BUTTON_COLOR,
      children: [
        SizedBox(
          width: widget.singleButtonWidth,
          child: (widget.showText)
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    severityToIcon(Severity.EASY, isDarkMode(context) ? (_severityIndex == 0 ? PRIMARY_COLOR : null) : null),
                    Text(severityToString(Severity.EASY), textAlign: TextAlign.center,
                        style: TextStyle(color: isDarkMode(context) ? (_severityIndex == 0 ? PRIMARY_COLOR : null) : null)),
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
                    severityToIcon(Severity.MEDIUM, isDarkMode(context) ? (_severityIndex == 1 ? PRIMARY_COLOR : null) : null),
                    Text(severityToString(Severity.MEDIUM), textAlign: TextAlign.center,
                        style: TextStyle(color: isDarkMode(context) ? (_severityIndex == 1 ? PRIMARY_COLOR : null) : null)),
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
                    severityToIcon(Severity.HARD, isDarkMode(context) ? (_severityIndex == 2 ? PRIMARY_COLOR : null) : null),
                    Text(severityToString(Severity.HARD), textAlign: TextAlign.center,
                        style: TextStyle(color: isDarkMode(context) ? (_severityIndex == 2 ? PRIMARY_COLOR : null) : null)),
                  ],
                )
              : severityToIcon(Severity.HARD),
        ),
      ],
      isSelected: _severitySelection,
      onPressed: (int index) {
        FocusScope.of(context).unfocus();
        widget.onChanged(Severity.values.elementAt(index));
        setState(() {
          if (_severityIndex != null) {
            _severitySelection[_severityIndex!] = false;
          }
          _severitySelection[index] = true;
          _severityIndex = index;
          debugPrint("new index $_severityIndex");
        });
      },
    );
  }

}
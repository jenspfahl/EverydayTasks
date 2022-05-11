import 'package:flutter/material.dart';
import 'package:personaltasklogger/model/Severity.dart';
import 'package:personaltasklogger/ui/utils.dart';

class ChoiceWidget extends StatefulWidget {
  final List<String> choices;
  final int? initialSelected;
  final ValueChanged<int> onChanged;

  const ChoiceWidget({required this.choices, this.initialSelected, required this.onChanged});
  
  @override
  _ChoiceWidgetState createState() => _ChoiceWidgetState();
}

class _ChoiceWidgetState extends State<ChoiceWidget> {
  int? _currentSelected;

  @override
  void initState() {
    super.initState();
    _initState();
  }

  @override
  void didUpdateWidget(covariant ChoiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _initState();
  }

  void _initState() {
    _currentSelected = widget.initialSelected;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(children: _buildChoices());
  }

  List<Widget> _buildChoices() {

    return widget.choices.asMap().map((index, choiceString) => MapEntry(index, SimpleDialogOption(
        onPressed: () {
          setState(() {
            _currentSelected = index;
            widget.onChanged(index);
          });
        },
        child: Row(
          children: [
            createCheckIcon(index == _currentSelected),
            Spacer(),
            Text(choiceString),
          ],
        ),
      )
    )).values.toList();
  }

}
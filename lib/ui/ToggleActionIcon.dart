import 'package:flutter/widgets.dart';

@immutable
class ToggleActionIcon extends StatefulWidget {
  final IconData _onIcon;
  final IconData _offIcon;
  final bool _toggled;

  ToggleActionIcon(this._onIcon, this._offIcon, this._toggled, [Key? key]) : super(key: key);

  @override
  State<StatefulWidget> createState() => ToggleActionIconState(_toggled);
}

class ToggleActionIconState extends State<ToggleActionIcon> {
  late bool _toggled;

  ToggleActionIconState(this._toggled);

  @override
  Widget build(BuildContext context) {
    return Icon(_toggled ? widget._onIcon : widget._offIcon);
  }

  void refresh(bool isToggled) {
    setState(() {
      _toggled = isToggled;
    });
  }

}

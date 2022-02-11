import 'package:flutter/widgets.dart';

class ToggleActionIcon extends StatefulWidget {
  final IconData _onIcon;
  final IconData _offIcon;
  final bool _toggled;

  _ToggleActionIconState? _state;

  ToggleActionIcon(this._onIcon, this._offIcon, this._toggled, [Key? key]) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    _state = _ToggleActionIconState(_toggled);
    return _state!;
  }

  void refresh(bool isToggled) {
    _state?.refresh(isToggled);
  }
}

class _ToggleActionIconState extends State<ToggleActionIcon> {
  late bool _toggled;

  _ToggleActionIconState(this._toggled);

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

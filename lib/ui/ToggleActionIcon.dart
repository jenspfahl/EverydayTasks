import 'package:flutter/widgets.dart';

class ToggleActionIcon extends StatefulWidget {
  final IconData _onIcon;
  final IconData _offIcon;
  final bool _toggled;

  _ToggleActionIconState? _state;

  ToggleActionIcon(this._onIcon, this._offIcon, this._toggled);

  @override
  State<StatefulWidget> createState() {
    _state = _ToggleActionIconState(_onIcon, _offIcon, _toggled);
    return _state!;
  }

  void refresh(bool isToggled) {
    _state?.refresh(isToggled);
  }
}

class _ToggleActionIconState extends State<ToggleActionIcon> {
  late IconData _onIcon;
  late IconData _offIcon;
  late bool _toggled;

  _ToggleActionIconState(this._onIcon, this._offIcon, this._toggled);

  @override
  Widget build(BuildContext context) {
    return Icon(_toggled ? _onIcon : _offIcon);
  }

  void refresh(bool isToggled) {
    setState(() {
      _toggled = isToggled;
    });
  }

}

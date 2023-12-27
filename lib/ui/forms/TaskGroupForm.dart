import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:personaltasklogger/db/repository/TaskGroupRepository.dart';
import 'package:personaltasklogger/model/TaskGroup.dart';
import 'package:personaltasklogger/ui/dialogs.dart';

class TaskGroupForm extends StatefulWidget {
  final TaskGroup? _taskGroup;
  final String formTitle;

  TaskGroupForm(this._taskGroup, {required this.formTitle});

  @override
  State<StatefulWidget> createState() {
    return _TaskGroupFormState();
  }
}

class _TaskGroupFormState extends State<TaskGroupForm> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();

  TaskGroup? _taskGroup;

  initState() {
    super.initState();

    if (widget._taskGroup != null) {
      _taskGroup = TaskGroup(
          id: widget._taskGroup!.id, 
        name: widget._taskGroup!.translatedName, 
        colorRGB: widget._taskGroup!.colorRGB,
        iconData: widget._taskGroup!.iconData,
      );
    }
    else {
      _taskGroup = TaskGroup(
        name: "",
        colorRGB: Colors.lime.shade800,
        iconData: Icons.token_outlined,
      );
    }
 
    _updateState();

  }

  void _updateState() {
      nameController.text = _taskGroup?.translatedName ?? "";
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.formTitle),
          actions: [
            Visibility(
              visible: _taskGroup != null && _taskGroup!.isPredefined(),
              child: IconButton(
                icon: const Icon(Icons.undo),
                onPressed: () {
                  showConfirmationDialog(
                    context,
                    translate('forms.task_group.reset.title'),
                    translate('forms.task_group.reset.message', args: {"name": _taskGroup!.translatedName}),
                    icon: const Icon(Icons.undo),
                    okPressed: () {
                      Navigator.pop(context); // dismiss dialog, should be moved in Dialogs.dart somehow

                      final predefinedTaskGroup = TaskGroupRepository.findPredefinedTaskGroupById(_taskGroup!.id!);
                      _taskGroup?.name = predefinedTaskGroup.name;
                      _taskGroup?.colorRGB = predefinedTaskGroup.colorRGB;
                      _taskGroup?.iconData = predefinedTaskGroup.iconData;
                      setState(() {
                        _updateState();
                      });
                    },
                    cancelPressed: () =>
                        Navigator.pop(context), // dismiss dialog, should be moved in Dialogs.dart somehow
                  );
                },
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Container(
            child: Builder(
              builder: (scaffoldContext) => Form(
                key: _formKey,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: translate('forms.task.title_hint'),
                          icon: _taskGroup!.getIcon(true),
                        ),
                        maxLength: 50,
                        keyboardType: TextInputType.text,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return translate('forms.common.title_emphasis');
                          }
                          return null;
                        },
                      ),
                      ButtonBar(
                        alignment: MainAxisAlignment.center,
                        //    buttonPadding: EdgeInsets.symmetric(horizontal: 0.0),
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              final iconData = await showIconPicker(context, translate('forms.task_group.change_icon.message'));
                              if (iconData != null) {
                                setState(() => _taskGroup!.iconData = iconData);
                              }
                            },
                            icon: _taskGroup!.getIcon(false),
                            label: Text(translate('forms.task_group.change_icon.title')),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              Color? _color;
                              showColorPicker(
                                  context,
                                  title: translate('forms.task_group.change_color.message'),
                                  initialColor: _taskGroup!.foregroundColor(context),
                                  onColorChanged: (color) => _color = color,
                                  onOkClicked: () {
                                    setState(() {
                                      if (_color != null) {
                                        _taskGroup!.colorRGB =
                                            _color!.withAlpha(100);
                                      }
                                    });
                                  }
                              );
                            },
                            icon: Icon(Icons.palette_outlined, color: _taskGroup!.foregroundColor(context)),
                            label: Text(translate('forms.task_group.change_color.title')),

                          ),

                        ],
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 26.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(double.infinity, 40), // double.infinity is the width and 30 is the height
                            ),
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {

                                if (_taskGroup == null) {
                                  _taskGroup = TaskGroup(name: nameController.text);
                                }
                                else {
                                    // update task template
                                  _taskGroup!.name = nameController.text;
                                }
                                Navigator.pop(context, _taskGroup);
                              }
                            },
                            child: Text(translate('forms.common.button_save')),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }



}

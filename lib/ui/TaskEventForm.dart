import 'package:flutter/material.dart';
import 'package:personaltasklogger/model/Severity.dart';
import 'package:personaltasklogger/model/TaskEvent.dart';
import 'package:personaltasklogger/ui/utils.dart';

class TaskEventForm extends StatefulWidget {
  final String _title;
  final TaskEvent? _taskEvent;

  TaskEventForm(this._title, [this._taskEvent]);

  @override
  State<StatefulWidget> createState() {
    return _TaskEventFormState(_taskEvent);
  }
}

class _TaskEventFormState extends State<TaskEventForm> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();

  late TaskEvent? _taskEvent;
  late List<bool> _severitySelection;
  late int _severityIndex;

  _TaskEventFormState([this._taskEvent]) {
    final severity =
        _taskEvent?.severity != null ? _taskEvent!.severity : Severity.MEDIUM;

    this._severityIndex = severity.index;
    this._severitySelection = List.generate(
        Severity.values.length, (index) => index == _severityIndex);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget._title),
      ),
      body: Builder(
        builder: (scaffoldContext) => Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextFormField(
                  controller: nameController,
                  maxLength: 50,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: descriptionController,
                  maxLength: 500,
                  maxLines: 3,
                ),
                Padding(
                  padding: EdgeInsets.only(top: 30.0),
                  child: Center(
                    child: ToggleButtons(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                      renderBorder: true,
                      borderWidth: 1.5,
                      borderColor: Colors.grey,
                      color: Colors.grey.shade600,
                      selectedBorderColor: Colors.blue,
                      children: [
                        SizedBox(
                          width: 100,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              severityToIcon(Severity.EASY),
                              Text('Easy going'),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              severityToIcon(Severity.MEDIUM),
                              Text('As always ok'),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              severityToIcon(Severity.HARD),
                              Text('Exhausting'),
                            ],
                          ),
                        ),
                      ],
                      isSelected: _severitySelection,
                      onPressed: (int index) {
                        setState(() {
                          _severitySelection[_severityIndex] = false;
                          _severitySelection[index] = true;
                          _severityIndex = index;
                        });
                      },
                    ),
                  ),
                ),
                Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        var taskEvent = TaskEvent.newInstance(
                          nameController.text,
                          descriptionController.text,
                          null,
                          null,
                          DateTime.now(),
                          DateTime.now().add(Duration(minutes: 5)),
                          Severity.values.elementAt(_severityIndex),
                        );
                        Navigator.pop(context, taskEvent);
                      }
                    },
                    child: Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

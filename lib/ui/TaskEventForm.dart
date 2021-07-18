import 'package:flutter/material.dart';
import 'package:personaltasklogger/model/TaskEvent.dart';

class TaskEventForm extends StatefulWidget {
  final String _title;
  final TaskEvent? _taskEvent;

  TaskEventForm(this._title, [this._taskEvent]);

  @override
  State<StatefulWidget> createState() {
    return _TaskEventFormState();
  }
}

class _TaskEventFormState extends State<TaskEventForm> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      var taskEvent = TaskEvent.newPlainInstance(
                          nameController.text,
                          DateTime.now(),
                          DateTime.now().add(Duration(minutes: 5)));
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
    );
  }
}

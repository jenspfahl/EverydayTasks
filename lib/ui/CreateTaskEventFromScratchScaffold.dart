import 'package:flutter/material.dart';
import 'package:personaltasklogger/db/repository/TaskEventRepository.dart';
import 'package:personaltasklogger/model/TaskEvent.dart';

class CreateTaskEventFromScratchScaffold extends Scaffold {
  CreateTaskEventFromScratchScaffold(BuildContext context)
      : super(
          appBar: AppBar(
            title: const Text('Create new Task Event'),
          ),
          body: _TaskEventForm(context),
        );
}

class _TaskEventForm extends StatefulWidget {
  _TaskEventForm(BuildContext context);

  @override
  State<StatefulWidget> createState() {
    return _TaskEventFormState();
  }
}

class _TaskEventFormState extends State<_TaskEventForm> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Form(
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
                    TaskEventRepository.insert(taskEvent).then((value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('New event created')));
                      Navigator.pop(context);
                    });
                  }
                },
                child: Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

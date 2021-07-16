import 'package:flutter/material.dart';
import 'package:personaltasklogger/ui/TaskEventsList.dart';

import 'CreateTaskEventFromScratchScaffold.dart';

class PersonalTaskLoggerScaffold extends Scaffold {
  PersonalTaskLoggerScaffold(BuildContext context)
      : super(
          appBar: AppBar(
            title: const Text('Personal Task Logger'),
            actions: [
              IconButton(
                icon: const Icon(Icons.list),
                onPressed: () {}, //_pushFavorite,
                tooltip: 'Saved Favorites',
              ),
            ],
          ),
          body: TaskEventsList(),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return Container(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Text(
                                'From what do you want to create a new log entry?'),
                            OutlinedButton(
                              child: const Text('From scratch'),
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (BuildContext context) {
                                      return CreateTaskEventFromScratchScaffold(
                                          context);
                                    },
                                  ),
                                );
                              },
                            ),
                            ElevatedButton(
                              child: const Text('From task template'),
                              onPressed: () => Navigator.pop(context),
                            )
                          ],
                        ),
                      ),
                    );
                  });
            },
            child: Icon(Icons.event_available),
          ),
          bottomNavigationBar: BottomNavigationBar(
            showUnselectedLabels: true,
            showSelectedLabels: true,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.add),
                label: 'Add',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.event_available),
                label: 'Logs',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.task_alt),
                label: 'Tasks',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                label: 'Favorites',
              ),
            ],
            selectedItemColor: Colors.lime[800],
            unselectedItemColor: Colors.grey.shade600,
            currentIndex: 1,
            // onTap: _onItemTapped,
          ),
        );
}

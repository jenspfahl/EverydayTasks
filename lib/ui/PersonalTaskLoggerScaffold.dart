import 'package:flutter/material.dart';
import 'package:personaltasklogger/ui/TaskEventsList.dart';

class PersonalTaskLoggerScaffold extends Scaffold {
  PersonalTaskLoggerScaffold()
      : super(
          appBar: AppBar(
            title: const Text('Personal Task Logger'),
            actions: [
              IconButton(
                icon: const Icon(Icons.list),
                onPressed: () {},//_pushFavorite,
                tooltip: 'Saved Favorites',
              ),
            ],
          ),
          body: TaskEventsList(),
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            child: Icon(Icons.event_available),
          ),
          bottomNavigationBar: BottomNavigationBar(

            items: const <BottomNavigationBarItem>[
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
            // onTap: _onItemTapped,
          ),
        );
}




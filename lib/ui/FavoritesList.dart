import 'package:flutter/material.dart';

import '../entity/Severity.dart';
import '../entity/TaskEvent.dart';

class FavoritesList extends StatefulWidget {
  @override
  State<FavoritesList> createState() => _FavoritesListState();
}

class _FavoritesListState extends State<FavoritesList> {
  final _events = <TaskEvent>[];
  final _favorites = <TaskEvent>{};
  final _biggerFont = const TextStyle(fontSize: 18.0);


  Widget _buildEvents() {

    var rows = _loadTaskEvents().map(_buildRow).toList();
    return ListView(
      children: rows,
    );

    /*
    return ListView.builder(
      //  padding: const EdgeInsets.all(3.0),
        itemBuilder: (context, i) {
          if (i.isOdd) return const Divider();

          final index = i ~/ 2;
          if (index >= _events.length) {
            _events.addAll(generateTaskEvents().take(10));
          }
          return _buildRow(_events[index]);
        });*/
  }


  Widget _buildRow(TaskEvent taskEvent) {
    final alreadyFavorite = _favorites.contains(taskEvent);

    var listTile = ListTile(
      title: Text(
        DateTime.now().toString(),
        style: TextStyle(color: Colors.grey, fontSize: 10.0),
      ),
      subtitle: Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          title: Text(taskEvent.name),
          subtitle: Text(taskEvent.originTaskGroup),
          //          backgroundColor: Colors.lime,
          children: <Widget>[
            Text(taskEvent.description),
            Text(taskEvent.severity.toString()),
            Text(taskEvent.startedAt.toString()),
            Text(taskEvent.finishedAt.toString()),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ButtonBar(
                  alignment: MainAxisAlignment.start,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (taskEvent.favorite) {
                            _favorites.remove(taskEvent);
                            taskEvent.favorite = false;
                          } else {
                            _favorites.add(taskEvent);
                            taskEvent.favorite = true;
                          }
                        });

                      },
                      child: Icon(taskEvent.favorite ? Icons.favorite : Icons.favorite_border),
                    ),
                  ],
                ),
                ButtonBar(
                  alignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        // Perform some action
                      },
                      child: const Text("Change"),
                    ),
                    TextButton(
                      onPressed: () {
                        // Perform some action
                      },
                      child: const Icon(Icons.delete),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return Column(
      children: [
        const Divider(),
        listTile
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Task Logger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _pushFavorite,
            tooltip: 'Saved Suggestions',
          ),
        ],
      ),
      body: _buildEvents(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.task),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Business',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'School',
          ),
        ],
        // currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        // onTap: _onItemTapped,
      ),
    );
  }

  void _pushFavorite() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          final tiles = _favorites.map(
            (taskEvent) {
              return ListTile(
                title: Text(
                  taskEvent.name,
                  style: _biggerFont,
                ),
              );
            },
          );
          final divided = tiles.isNotEmpty
              ? ListTile.divideTiles(
                  context: context,
                  tiles: tiles,
                ).toList()
              : <Widget>[];

          return Scaffold(
            appBar: AppBar(
              title: const Text('Favorite Task Events'),
            ),
            body: ListView(children: divided),
          );
        },
      ),
    );
  }

  List<TaskEvent> _loadTaskEvents() {
    return [
        TaskEvent(1, "Wash up", "Washing all up", "Household/Daily", null,
            DateTime.now(), DateTime.now().add(Duration(minutes: 15)), Severity.MEDIUM, false),
       TaskEvent(2, "Clean kitchen", "Clean all in kitchen", "Household/Daily", null,
            DateTime.now(), DateTime.now().add(Duration(minutes: 30)), Severity.MEDIUM, true),
    ];
  }
}


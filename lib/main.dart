import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

import 'utils.dart';

typedef TodoListItemData = List<TodoItem>;
void main() {
  runApp(const MyApp());
}

final _todoListKey = GlobalKey<_TodoListState>();
final _animatedListKey = GlobalKey<AnimatedListState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'To-Do App',
      home: MyHomePage(title: 'To-Do App'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    final todoItems = Future.delayed(
        const Duration(seconds: 3), () => TodoListController().getTodos());

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea(
        child: Container(
          alignment: Alignment.center,
          // width: 300,
          decoration:
              const BoxDecoration(color: Color.fromARGB(255, 241, 238, 238)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 30),
            child: FutureBuilder<(String, TodoListItemData)>(
                future: todoItems,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return TodoList(
                        key: _todoListKey, todoItem: snapshot.data!.$2);
                  } else if (snapshot.hasError) {
                    String error = snapshot.error.toString();
                    if (snapshot.error is Error) {
                      error = (snapshot.error as Error).stackTrace.toString();
                    } else if (snapshot.error is TodoStoreError) {
                      error = (snapshot.error as TodoStoreError)
                          .stackTrace
                          .toString();
                    }
                    return Text(
                      'Error loading your saved tasks.\n$error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 24),
                    );
                  } else {
                    return CircularProgressIndicator(
                      color: Colors.blue.shade900,
                    );
                  }
                }),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Add',
        hoverColor: Colors.blue.shade700,
        hoverElevation: 50,
        backgroundColor: Colors.blue.shade900,
        shape: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.add,
              color: Colors.white, size: 30, semanticLabel: 'Add Task'),
        ),
      ),
    );
  }
}

class TodoList extends StatefulWidget {
  const TodoList({super.key, required this.todoItem});
  final TodoListItemData todoItem;

  @override
  State<StatefulWidget> createState() {
    return _TodoListState();
  }
}

class _TodoListState extends State<TodoList> {
  final _todoController = TodoListController();
  final _textController = TextEditingController();
  late TodoListItemData _todoItems;

  @override
  void initState() {
    _todoItems = widget.todoItem;
    super.initState();
  }

  @override
  dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> addTodo() async {
    if (_textController.text.isEmpty || _textController.text.trim() == '') {
      return;
    }
    final existingItem =
        _todoItems.any((element) => element.title == _textController.text);
    if (!existingItem) {
      try {
         _animatedListKey.currentState?.insertItem(_todoItems.length,
              duration: const Duration(milliseconds: 500));
          _todoItems.add(TodoItem(
              title: _textController.text,
              createdAt: DateTime.timestamp().toString()));
        await _todoController.saveTodos(
          _todoItems,
        );
        setState(() {
          _textController.text = '';
        });
      } catch (e) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Column(
        children: [
          TextField(
            controller: _textController,
            decoration: InputDecoration(
                suffix: IconButton(
                  onPressed: addTodo,
                  icon: Icon(
                    Icons.add_circle,
                    size: 30,
                    color: Colors.blue.shade900,
                    semanticLabel: 'Add Task',
                  ),
                ),
                hintText: 'Add a new task',
                hintStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.normal)),
            cursorHeight: 30,
            textAlignVertical: TextAlignVertical.bottom,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
            maxLength: 100,
          ),
          const SizedBox(
            height: 10,
          ),
          Container(
            width: 300,
            padding:
                const EdgeInsets.only(top: 10, bottom: 5, left: 10, right: 10),
            height: 350,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(5)),
              color: Color.fromARGB(255, 228, 234, 236),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(135, 65, 63, 63),
                  blurRadius: 2,
                  blurStyle: BlurStyle.solid,
                  spreadRadius: 1,
                )
              ],
            ),
            child: AnimatedList(
              key: _animatedListKey,
              initialItemCount: _todoItems.length,
              itemBuilder: (context, index, animation) {
                return SlideTransition(
                  position: Tween(
                          begin: const Offset(1.0,
                              0.0), // Start from the right edge of the screen
                          end: const Offset(
                              0.0, 0.0) // End at the center of the screen
                          )
                      .animate(animation),
                  child: TodoListItem(
                      key: ValueKey(_todoItems[index].title),
                      listItem: _todoItems[index]),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class TodoListItem extends StatefulWidget {
  final TodoItem listItem;
  const TodoListItem({super.key, required this.listItem});

  @override
  State<TodoListItem> createState() => _TodoListItemState();
}

class _TodoListItemState extends State<TodoListItem> {
  late String _title;
  late bool _completed;
  late String _createdAt;
  late TodoListController _todoController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _title = widget.listItem.title;
    _completed = widget.listItem.completed;
    _createdAt = widget.listItem.createdAt;
    _todoController = _todoListKey.currentState!._todoController;
  }

  Future<void> _onDelete(BuildContext context) async {
    final item = widget.listItem;
    final todoList = _todoListKey.currentState!._todoItems;
    final index = todoList.indexOf(item);
    if (index == -1) return;
    try {
      await _todoController.saveTodos(todoList);
      _animatedListKey.currentState?.removeItem(
          index,
          (context, animation) => SlideTransition(
                position: Tween(
                        begin: const Offset(0.0, 1.0),
                        end: const Offset(0.0, 0.0))
                    .animate(CurvedAnimation(
                        parent: animation, curve: Curves.easeOutExpo)),
                child: TodoListItem(key: ValueKey(item.title), listItem: item),
              ));
      todoList.removeAt(index);
      _todoListKey.currentState!.setState(() {});
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: _completed,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _completed = value;
              });
            }
          },
          shape: const CircleBorder(),
        ),
        Expanded(child: Text(_title)),
        IconButton(
          onPressed: () {
            _onDelete(context);
          },
          icon: const Icon(Icons.delete, color: Colors.red),
          iconSize: 20,
        ),
      ],
    );
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'main.dart';

class TodoListController {
  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      var result = await permission.request();
      if (result == PermissionStatus.granted) {
        return true;
      }
    }
    return false;
  }

  Future<String> get _localPath async {
    Directory? directory;
    if (Platform.isAndroid) {
      if (await _requestPermission(Permission.storage) ||
          await _requestPermission(Permission.manageExternalStorage)) {
        try {
          directory = await getExternalStorageDirectory();
          if (directory != null && !await directory.exists()) {
            directory = await directory.create(recursive: true);
          }
          return directory!.path;
        } on UnsupportedError {
          throw TodoStoreError('Folder not supported');
        }
      }
    } else if (Platform.isIOS) {
      if (await _requestPermission(Permission.storage)) {
        directory = await getApplicationDocumentsDirectory();
        if (!await directory.exists()) {
          directory = await directory.create(recursive: true);
        }
        return directory.path;
      }
    }
    throw TodoStoreError('File permission not granted');
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    final file = File('$path/todos.json');
    if (await file.exists()) {
      return file;
    }
    final file2 = await file.create(recursive: true);
    return file2.writeAsString('{"todos": []}');
  }

  Future<TodoListItemData> _parseTodos(String contents) async {
    final json = jsonDecode(contents);
    if (json['todos'] == null) {
      await (await _localFile).writeAsString('{"todos": []}');
      throw TodoStoreError('Invalid JSON: \n$contents');
    }
    try {  
      final List el = json['todos'];
      return el.map((el) {
        return TodoItem(
            title: el['title'],
            completed: el['completed'],
            createdAt: el['createdAt']);
      }).toList();
  }
  catch (e){
    rethrow;
  }
  }

  Future<(String, TodoListItemData)> getTodos() async {
    (String, TodoListItemData) result;
    try {
      final file = await _localFile;
      final String contents = await file.readAsString();
      result = (file.path, await _parseTodos(contents));
      return result;
    } on TodoStoreError {
      rethrow;
    } catch (e) {
      result = ('$e', []);
      if(e is Error){
       result = ('${e.stackTrace}', []);
      }
      return result;
    }
  }

  Future<void> saveTodos(TodoListItemData todoItems,
      {void Function()? callback}) async {
    if (await _requestPermission(Permission.storage) ||
        await _requestPermission(Permission.manageExternalStorage)) {
      try {
        final file = await _localFile;
        final Map<String, List<Map<String, dynamic>>> todoMap = {};
        todoMap['todos'] = todoItems.map((e) => e.toMap()).toList();
        final String contents = jsonEncode(todoMap);
        await file.writeAsString(contents);
      } catch (e) {
        if (callback != null) {
          callback();
        }
      }
      return;
    }
    if (callback != null) {
      callback();
    }
  }
}

class TodoItem {
  final String title;
  final bool completed;
  final String createdAt;

  TodoItem({
    required this.title,
    this.completed = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'completed': completed,
      'createdAt': createdAt,
    };
  }
}

class TodoStoreError extends Error {
  final String message;
  TodoStoreError(this.message);
}

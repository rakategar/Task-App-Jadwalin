import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:todark/app/data/schema.dart';
import 'package:todark/app/services/notification.dart';
import 'package:todark/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:todark/model/user.dart'; // Sesuaikan dengan path yang benar

final FirebaseFirestore firestore = FirebaseFirestore.instance;

class TodoController extends GetxController {
  final tasks = <Tasks>[].obs;
  final todos = <Todos>[].obs;

  @override
  void onInit() {
    super.onInit();
    tasks.assignAll(isar.tasks.where().sortByIndex().findAllSync());
    todos.assignAll(isar.todos.where().findAllSync());
  }

  Future<void> addTaskToFirestore(Tasks task) async {
    try {
      // Membuat referensi untuk koleksi "tasks" di Firestore
      final taskCollection = firestore.collection('tasks');

      // Menyimpan data tugas ke Firestore
      await taskCollection.add({
        'title': task.title,
        'description': task.description,
        'taskColor': task.taskColor,
        // Tambahkan bidang lain yang Anda butuhkan
      });

      // Setelah berhasil disimpan di Firestore, tambahkan juga ke penyimpanan lokal (Isar).
      await isar.writeTxn(() async {
        tasks.add(task);
        await isar.tasks.put(task);
      });

      if (kDebugMode) {
        print(
            'Data tugas berhasil disimpan di Firestore dan penyimpanan lokal.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Terjadi kesalahan saat menyimpan data tugas: $e');
      }
    }
  }

  // Tasks

  Future<void> addTask(String title, String description, Color myColor) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      // Ganti ini dengan cara yang sesuai untuk mendapatkan objek User yang sesuai
      final taskCreate = Tasks(
        title: title,
        description: description,
        taskColor: myColor.value,
        uid: user!.uid, // Mengambil UID dari objek User
      );

      final firestore = FirebaseFirestore.instance;
      final taskCollection = firestore.collection('tasks');

      // Simpan tugas ke Firestore.
      await taskCollection.add({
        'title': taskCreate.title,
        'description': taskCreate.description,
        'taskColor': taskCreate.taskColor,
        'uid': taskCreate.uid,
      });

      // Selanjutnya, Anda dapat menambahkan tugas ke Isar atau penyimpanan lokal lainnya sesuai kebutuhan.
      await isar.writeTxn(() async {
        tasks.add(taskCreate);
        await isar.tasks.put(taskCreate);
      });

      EasyLoading.showSuccess('createCategory'.tr,
          duration: const Duration(milliseconds: 500));
    } catch (e) {
      print('Error adding task: $e');
      EasyLoading.showError('Failed to create task',
          duration: const Duration(milliseconds: 500));
    }
  }

  Future<void> updateTask(
      Tasks task, String title, String desc, Color myColor) async {
    await isar.writeTxn(() async {
      task.title = title;
      task.description = desc;
      task.taskColor = myColor.value;
      await isar.tasks.put(task);

      var newTask = task;
      int oldIdx = tasks.indexOf(task);
      tasks[oldIdx] = newTask;
      tasks.refresh();
      todos.refresh();
    });
    EasyLoading.showSuccess('editCategory'.tr,
        duration: const Duration(milliseconds: 500));
  }

  Future<void> deleteTask(Tasks task) async {
    // Delete Notification
    List<Todos> getTodo;
    final taskCollection = isar.todos;
    getTodo = await taskCollection
        .filter()
        .task((q) => q.idEqualTo(task.id))
        .findAll();

    for (var element in getTodo) {
      if (element.todoCompletedTime != null) {
        await flutterLocalNotificationsPlugin.cancel(element.id);
      }
    }
    // Delete Todos
    await isar.writeTxn(() async {
      todos.removeWhere((todo) => todo.task.value == task);
      await isar.todos.filter().task((q) => q.idEqualTo(task.id)).deleteAll();
    });
    // Delete Task
    await isar.writeTxn(() async {
      tasks.remove(task);
      await isar.tasks.delete(task.id);
    });
    EasyLoading.showSuccess('categoryDelete'.tr,
        duration: const Duration(milliseconds: 500));
  }

  Future<void> archiveTask(Tasks task) async {
    // Delete Notification
    List<Todos> getTodo;
    final taskCollection = isar.todos;
    getTodo = await taskCollection
        .filter()
        .task((q) => q.idEqualTo(task.id))
        .findAll();

    for (var element in getTodo) {
      if (element.todoCompletedTime != null) {
        await flutterLocalNotificationsPlugin.cancel(element.id);
      }
    }
    // Archive Task
    await isar.writeTxn(() async {
      task.archive = true;
      await isar.tasks.put(task);

      tasks.refresh();
      todos.refresh();
    });
    EasyLoading.showSuccess('taskArchive'.tr,
        duration: const Duration(milliseconds: 500));
  }

  Future<void> noArchiveTask(Tasks task) async {
    // Create Notification
    List<Todos> getTodo;
    final taskCollection = isar.todos;
    getTodo = await taskCollection
        .filter()
        .task((q) => q.idEqualTo(task.id))
        .findAll();

    for (var element in getTodo) {
      if (element.todoCompletedTime != null) {
        NotificationShow().showNotification(
          element.id,
          element.name,
          element.description,
          element.todoCompletedTime,
        );
      }
    }
    // No archive Task
    await isar.writeTxn(() async {
      task.archive = false;
      await isar.tasks.put(task);

      tasks.refresh();
      todos.refresh();
    });
    EasyLoading.showSuccess('noTaskArchive'.tr,
        duration: const Duration(milliseconds: 500));
  }

  // Todos
  Future<void> addTodo(
      Tasks task, String title, String desc, String time) async {
    DateTime? date;
    if (time.isNotEmpty) {
      date = DateFormat.yMMMEd(locale.languageCode).add_Hm().parse(time);
    }
    final todosCollection = isar.todos;
    List<Todos> getTodos;
    getTodos = await todosCollection
        .filter()
        .nameEqualTo(title)
        .task((q) => q.idEqualTo(task.id))
        .todoCompletedTimeEqualTo(date)
        .findAll();

    final todosCreate = Todos(
      name: title,
      description: desc,
      todoCompletedTime: date,
    )..task.value = task;

    if (getTodos.isEmpty) {
      await isar.writeTxn(() async {
        todos.add(todosCreate);
        await isar.todos.put(todosCreate);
        await todosCreate.task.save();
        if (time.isNotEmpty) {
          NotificationShow().showNotification(
            todosCreate.id,
            todosCreate.name,
            todosCreate.description,
            date,
          );
        }
      });
      EasyLoading.showSuccess('taskCreate'.tr,
          duration: const Duration(milliseconds: 500));
    } else {
      EasyLoading.showError('duplicateTask'.tr,
          duration: const Duration(milliseconds: 500));
    }
  }

  Future<void> updateTodoCheck(Todos todo) async {
    await isar.writeTxn(() async => isar.todos.put(todo));
    todos.refresh();
  }

  Future<void> updateTodo(
      Todos todo, Tasks task, String title, String desc, String time) async {
    DateTime? date;
    if (time.isNotEmpty) {
      date = DateFormat.yMMMEd(locale.languageCode).add_Hm().parse(time);
    }
    await isar.writeTxn(() async {
      todo.name = title;
      todo.description = desc;
      todo.todoCompletedTime = date;
      todo.task.value = task;
      await isar.todos.put(todo);
      await todo.task.save();

      var newTodo = todo;
      int oldIdx = todos.indexOf(todo);
      todos[oldIdx] = newTodo;
      todos.refresh();

      if (time.isNotEmpty) {
        await flutterLocalNotificationsPlugin.cancel(todo.id);
        NotificationShow().showNotification(
          todo.id,
          todo.name,
          todo.description,
          date,
        );
      } else {
        await flutterLocalNotificationsPlugin.cancel(todo.id);
      }
    });
    EasyLoading.showSuccess('update'.tr,
        duration: const Duration(milliseconds: 500));
  }

  Future<void> deleteTodo(Todos todo) async {
    await isar.writeTxn(() async {
      todos.remove(todo);
      await isar.todos.delete(todo.id);
      if (todo.todoCompletedTime != null) {
        await flutterLocalNotificationsPlugin.cancel(todo.id);
      }
    });
    EasyLoading.showSuccess('taskDelete'.tr,
        duration: const Duration(milliseconds: 500));
  }

  int createdAllTodos() {
    return todos.where((todo) => todo.task.value?.archive == false).length;
  }

  int completedAllTodos() {
    return todos
        .where((todo) => todo.task.value?.archive == false && todo.done == true)
        .length;
  }

  int createdAllTodosTask(Tasks task) {
    return todos.where((todo) => todo.task.value?.id == task.id).length;
  }

  int completedAllTodosTask(Tasks task) {
    return todos
        .where((todo) => todo.task.value?.id == task.id && todo.done == true)
        .length;
  }
}

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';


void main() {
  runApp(const PlannerApp());
}

class PlannerApp extends StatelessWidget {
  const PlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Planner App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TaskScreen(),
    );
  }
}

class Task {
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;

  Task({
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'],
      description: json['description'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
    );
  }
}

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final List<Task> tasks = [];
  DateTime selectedDate = DateTime.now();
  DateTime startOfWeek = DateTime.now();

  @override
  void initState() {
    super.initState();
    startOfWeek = getWeekStart(DateTime.now());
    _loadTasks();
  }

  DateTime getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  List<DateTime> get weekDays {
    return List.generate(7, (index) {
      return startOfWeek.add(Duration(days: index));
    });
  }

  List<Task> get filteredTasks {
    return tasks.where((task) {
      return task.startTime.year == selectedDate.year &&
          task.startTime.month == selectedDate.month &&
          task.startTime.day == selectedDate.day;
    }).toList();
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();

    final data = tasks.map((t) => t.toJson()).toList();

    prefs.setString('tasks', jsonEncode(data));
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();

    final String? data = prefs.getString('tasks');

    if (data != null) {
      final List decoded = jsonDecode(data);

      setState(() {
        tasks.clear();
        tasks.addAll(decoded.map((e) => Task.fromJson(e)).toList());
      });
    }
  }

  void _addTask(
    String title,
    String description,
    DateTime start,
    DateTime end,
  ) {
    setState(() {
      tasks.add(Task(
        title: title,
        description: description,
        startTime: start,
        endTime: end,
      ));

      tasks.sort((a, b) => a.startTime.compareTo(b.startTime));
    });
    _saveTasks();
  }

  void _openAddDialog() {
  final titleController = TextEditingController();
  final descController = TextEditingController();

  TimeOfDay? startTime;
  TimeOfDay? endTime;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Новая задача"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Название"),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: "Описание"),
                ),
                const SizedBox(height: 10),

                // START TIME
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setStateDialog(() {
                        startTime = picked;
                      });
                    }
                  },
                  child: Text(
                    startTime == null
                        ? "Выбрать время начала"
                        : "Начало: ${startTime!.format(context)}",
                  ),
                ),

                const SizedBox(height: 15),

                // END TIME
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setStateDialog(() {
                        endTime = picked;
                      });
                    }
                  },
                  child: Text(
                    endTime == null
                        ? "Выбрать время окончания"
                        : "Конец: ${endTime!.format(context)}",
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Отмена"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (startTime == null || endTime == null) return;

                  final now = DateTime.now();

                  _addTask(
                    titleController.text,
                    descController.text,
                    DateTime(
                      now.year,
                      now.month,
                      now.day,
                      startTime!.hour,
                      startTime!.minute,
                    ),
                    DateTime(
                      now.year,
                      now.month,
                      now.day,
                      endTime!.hour,
                      endTime!.minute,
                    ),
                  );

                  Navigator.pop(context);
                },
                child: const Text("Добавить"),
              ),
            ],
          );
        },
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${selectedDate.day.toString().padLeft(2, '0')}."
          "${selectedDate.month.toString().padLeft(2, '0')}."
          "${selectedDate.year}",
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                selectedDate = selectedDate.subtract(const Duration(days: 1));
                startOfWeek = getWeekStart(selectedDate);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                selectedDate = selectedDate.add(const Duration(days: 1));
                startOfWeek = getWeekStart(selectedDate);
              });
            },
          ),
        ],
      ),

      body: Column(
        children: [
          Container(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: weekDays.length,
              itemBuilder: (context, index) {
                final day = weekDays[index];

                final isSelected =
                    day.year == selectedDate.year &&
                    day.month == selectedDate.month &&
                    day.day == selectedDate.day;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDate = day;
                      startOfWeek = getWeekStart(day);
                    });
                  },
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"][day.weekday - 1],
                            style: TextStyle(
                              color: isSelected ? Colors.white70 : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            "${day.day.toString().padLeft(2, '0')}.${day.month.toString().padLeft(2, '0')}",
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: tasks.isEmpty
          ? const Center(child: Text("Нет задач"))
          : ListView.builder(
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                final task = filteredTasks[index];
                final duration = task.endTime.difference(task.startTime).inMinutes;
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ЛЕВАЯ КОЛОНКА (ВРЕМЯ)
                      SizedBox(
                        width: 80,
                        child: Text(
                          "${task.startTime.hour.toString().padLeft(2, '0')}:"
                          "${task.startTime.minute.toString().padLeft(2, '0')}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),

                      // ЛИНИЯ (визуальный таймлайн)
                      Container(
                        width: 2,
                        height: 60,
                        color: Colors.blue,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),

                      // ПРАВАЯ ЧАСТЬ (ЗАДАЧА)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: task.endTime
                                          .difference(task.startTime)
                                          .inMinutes >
                                      60
                                  ? Colors.red
                                  : Colors.blue,
                              width: 2,
                            ),
                          ),
                          child: Card(
                            elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(task.description.isEmpty ? "Без описания" : task.description,
                                ),
                                const SizedBox(height: 6),

                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${task.startTime.hour.toString().padLeft(2, '0')}:${task.startTime.minute.toString().padLeft(2, '0')} - "
                                      "${task.endTime.hour.toString().padLeft(2, '0')}:${task.endTime.minute.toString().padLeft(2, '0')}",
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
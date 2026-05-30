import 'package:flutter/material.dart';

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
}

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final List<Task> tasks = [];

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
        title: const Text("Планировщик дня"),
      ),
      body: tasks.isEmpty
          ? const Center(child: Text("Нет задач"))
          : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(task.title),
                    subtitle: Text(
                      "${task.startTime.hour.toString().padLeft(2, '0')}:${task.startTime.minute.toString().padLeft(2, '0')} - "
                      "${task.endTime.hour.toString().padLeft(2, '0')}:${task.endTime.minute.toString().padLeft(2, '0')}\n"
                      "${task.description}",
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
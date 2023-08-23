import 'package:isar/isar.dart';
import 'package:todark/app/data/schema.dart';
import 'package:todark/app/services/controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:todark/app/widgets/my_delegate.dart';
import 'package:todark/app/widgets/todos_list.dart';
import 'package:todark/main.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final todoController = Get.put(TodoController());
  DateTime selectedDay = DateTime.now();
  DateTime firstDay = DateTime.now().add(const Duration(days: -1000));
  DateTime lastDay = DateTime.now().add(const Duration(days: 1000));
  CalendarFormat calendarFormat = CalendarFormat.week;

  var todos = <Todos>[];
  int countTotalTodos = 0;
  int countDoneTodos = 0;

  @override
  void initState() {
    getCountTodos();
    getTodosAll();
    super.initState();
  }

  getCountTodos() async {
    countTotalTodos =
        await todoController.getCountTotalTodosCalendar(selectedDay);
    countDoneTodos =
        await todoController.getCountDoneTodosCalendar(selectedDay);
  }

  getTodosAll() async {
    final todosCollection = isar.todos;
    List<Todos> getTodos;
    getTodos = await todosCollection
        .filter()
        .doneEqualTo(false)
        .todoCompletedTimeIsNotNull()
        .task((q) => q.archiveEqualTo(false))
        .findAll();
    setState(() {
      todos = getTodos;
    });
  }

  int getCountTotalTodosCalendar(DateTime date) => todos
      .where((e) =>
          e.todoCompletedTime != null &&
          e.task.value!.archive == false &&
          DateTime(date.year, date.month, date.day, 0, -1)
              .isBefore(e.todoCompletedTime!) &&
          DateTime(date.year, date.month, date.day, 23, 60)
              .isAfter(e.todoCompletedTime!))
      .length;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: NestedScrollView(
        physics: const NeverScrollableScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: TableCalendar(
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    return getCountTotalTodosCalendar(day) != 0
                        ? selectedDay.isAtSameMomentAs(day)
                            ? Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: Colors.amber,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    getCountTotalTodosCalendar(day).toString(),
                                    style:
                                        context.textTheme.bodyLarge?.copyWith(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                getCountTotalTodosCalendar(day).toString(),
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              )
                        : null;
                  },
                ),
                startingDayOfWeek: StartingDayOfWeek.monday,
                firstDay: firstDay,
                lastDay: lastDay,
                focusedDay: selectedDay,
                locale: locale.languageCode,
                weekendDays: const [DateTime.sunday],
                availableCalendarFormats: {
                  CalendarFormat.month: 'month'.tr,
                  CalendarFormat.twoWeeks: 'two_week'.tr,
                  CalendarFormat.week: 'week'.tr
                },
                selectedDayPredicate: (day) {
                  return isSameDay(selectedDay, day);
                },
                onDaySelected: (selected, focused) {
                  setState(() {
                    selectedDay = selected;
                  });
                  getCountTodos();
                },
                onPageChanged: (focused) {
                  setState(() {
                    selectedDay = focused;
                  });
                  getCountTodos();
                },
                calendarFormat: calendarFormat,
                onFormatChanged: (format) {
                  setState(
                    () {
                      calendarFormat = format;
                    },
                  );
                },
              ),
            ),
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverPersistentHeader(
                delegate: MyDelegate(
                  TabBar(
                    isScrollable: true,
                    dividerColor: Colors.transparent,
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) {
                        return Colors.transparent;
                      },
                    ),
                    tabs: [
                      Tab(text: 'doing'.tr),
                      Tab(text: 'done'.tr),
                    ],
                  ),
                ),
                floating: true,
                pinned: true,
              ),
            ),
          ];
        },
        body: TabBarView(
          children: [
            TodosList(
              calendare: true,
              allTask: false,
              done: false,
              selectedDay: selectedDay,
            ),
            TodosList(
              calendare: true,
              allTask: false,
              done: true,
              selectedDay: selectedDay,
            ),
          ],
        ),
      ),
    );
  }
}

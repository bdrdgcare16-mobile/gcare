import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/task_service.dart';
import 'services/user_session.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  List<Task> tasks = [];
  List<Task> allTasks = []; // Store all tasks for filtering
  String? selectedFilter; // Track selected filter
  bool _isLoading = true;

  // Color scheme
  final Color primaryColor = const Color(0xFF2196F3);
  final Color backgroundColor = const Color(0xFFE3F2FD);
  final Color mainTextColor = const Color(0xFF1A1A1A);
  final Color secondaryTextColor = const Color(0xFF666666);

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await UserSession.instance.loadUserSession();
      
      List<Task> userTasks;
      if (UserSession.instance.isAdmin) {
        userTasks = await TaskService.getAllTasks();
      } else {
        userTasks = await TaskService.getMyTasks();
      }
      
      setState(() {
        allTasks = userTasks;
        tasks = userTasks;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load tasks: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Colors.green;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'PENDING':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          UserSession.instance.isAdmin ? 'All Tasks' : 'My Tasks',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
          ),
        ],
      ),
      body: Column(
        children: [
          // Task Summary Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  UserSession.instance.isAdmin ? 'All Tasks Overview' : 'My Tasks Overview',
                  style: TextStyle(
                    color: mainTextColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  UserSession.instance.isAdmin ? 'Manage all tasks and assignments' : 'Manage your tasks and assignments',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryCard('Total', allTasks.length.toString(), Icons.assignment, null),
                    _summaryCard('Completed', allTasks.where((t) => t.status == 'COMPLETED').length.toString(), Icons.check_circle, 'COMPLETED'),
                    _summaryCard('In Progress', allTasks.where((t) => t.status == 'IN_PROGRESS').length.toString(), Icons.pending, 'IN_PROGRESS'),
                  ],
                ),
                if (selectedFilter != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primaryColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_list, color: primaryColor, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Showing: ${selectedFilter == 'COMPLETED' ? 'Completed' : selectedFilter == 'IN_PROGRESS' ? 'In Progress' : 'All'} Tasks',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedFilter = null;
                              tasks = allTasks;
                            });
                          },
                          child: Icon(Icons.close, color: primaryColor, size: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Task List or Loading
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading tasks...'),
                      ],
                    ),
                  )
                : tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tasks found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTasks,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            return _buildTaskCard(tasks[index], index);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: UserSession.instance.isAdmin
          ? FloatingActionButton(
              onPressed: () => _showAddTaskDialog(),
              backgroundColor: primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, String? filter) {
    final isSelected = selectedFilter == filter;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (selectedFilter == filter) {
            // If clicking the same filter, clear it
            selectedFilter = null;
            tasks = allTasks;
          } else {
            // Apply new filter
            selectedFilter = filter;
            if (filter == null) {
              tasks = allTasks;
            } else {
              tasks = allTasks.where((task) => task.status == filter).toList();
            }
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: primaryColor, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon, 
              color: isSelected ? primaryColor : primaryColor, 
              size: 24
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSelected ? primaryColor : mainTextColor,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? primaryColor : secondaryTextColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Task status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(task.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task.status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Actions menu
                if (UserSession.instance.isAdmin)
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'delete') {
                        if (!mounted) return;
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Task'),
                            content: Text('Are you sure you want to delete "${task.title}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (!mounted) return;
                        if (confirm == true) {
                          await TaskService.deleteTask(task.id);
                          if (!mounted) return;
                          _loadTasks();
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Task title and description
            Text(
              task.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: mainTextColor,
              ),
            ),
            const SizedBox(height: 8),
            if (task.description != null && task.description!.isNotEmpty)
              Text(
                task.description!,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 14,
                ),
              ),
            const SizedBox(height: 16),
            
            // Due date
            if (task.dueDate != null)
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: secondaryTextColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Due: ${DateFormat('dd MMM yyyy').format(task.dueDate!)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            
            // Action button
            if (task.status != 'COMPLETED')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await TaskService.updateTask(
                        taskId: task.id,
                        status: 'COMPLETED',
                      );
                      
                      // Update the task status locally for immediate UI update
                      setState(() {
                        task = Task(
                          id: task.id,
                          userId: task.userId,
                          title: task.title,
                          description: task.description,
                          status: 'COMPLETED',
                          dueDate: task.dueDate,
                          createdAt: task.createdAt,
                          user: task.user,
                        );
                        
                        // Update the task in both lists
                        final allIndex = allTasks.indexWhere((t) => t.id == task.id);
                        if (allIndex != -1) {
                          allTasks[allIndex] = task;
                        }
                        
                        final index = tasks.indexWhere((t) => t.id == task.id);
                        if (index != -1) {
                          tasks[index] = task;
                        }
                        
                        // Reapply filter if active
                        if (selectedFilter != null) {
                          tasks = allTasks.where((t) => t.status == selectedFilter).toList();
                        }
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Task "${task.title}" marked as completed!'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update task: $e'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Mark as Completed',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => const TaskDialog(),
    ).then((result) {
      if (result == true) {
        _loadTasks();
      }
    });
  }
}

class TaskDialog extends StatefulWidget {
  final Task? task;
  const TaskDialog({this.task, super.key});

  @override
  _TaskDialogState createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  String _selectedStatus = 'PENDING';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descController = TextEditingController(text: widget.task?.description ?? '');
    _selectedStatus = widget.task?.status ?? 'PENDING';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.task == null ? 'Add Task' : 'Edit Task'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => v == null || v.isEmpty ? 'Enter title' : null,
            ),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              items: ['PENDING', 'IN_PROGRESS', 'COMPLETED']
                  .map((status) => DropdownMenuItem<String>(
                        value: status,
                        child: Text(status.replaceAll('_', ' ')),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedStatus = val!),
              decoration: const InputDecoration(labelText: 'Status'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              try {
                if (widget.task == null) {
                  await TaskService.createTask(
                    userId: UserSession.instance.userId!,
                    title: _titleController.text,
                    description: _descController.text,
                    status: _selectedStatus,
                  );
                } else {
                  await TaskService.updateTask(
                    taskId: widget.task!.id,
                    title: _titleController.text,
                    description: _descController.text,
                    status: _selectedStatus,
                  );
                }
                Navigator.pop(context, true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to save task: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

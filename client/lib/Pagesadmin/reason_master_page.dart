// import 'package:flutter/material.dart';

// class ReasonMasterPage extends StatefulWidget {
//   const ReasonMasterPage({super.key});

//   @override
//   _ReasonMasterPageState createState() => _ReasonMasterPageState();
// }

// class _ReasonMasterPageState extends State<ReasonMasterPage> {
//   final TextEditingController _searchController = TextEditingController();
//   final TextEditingController reasonInputController = TextEditingController();
//   String? selectedTable;

//   final List<String> tableOptions = [
//     'Regularization Reason',
//     'Half Day Reason',
//     'Comp Off Check In Reason',
//     'Week Off Check In Reason',
//     'Leave Check In Reason',
//     'Check Out Early Reason',
//     'Permission Reason',
//   ];

//   final List<Map<String, String>> allReasons = [
//     {
//       'id': '1',
//       'tableName': 'Regularization Reason',
//       'reason': 'Regularization Reason 1',
//       'date': '22-01-2025',
//       'status': 'Default',
//     },
//     {
//       'id': '2',
//       'tableName': 'Half Day Reason',
//       'reason': 'Emergency',
//       'date': '22-01-2025',
//       'status': 'Default',
//     },
//   ];

//   List<Map<String, String>> filteredReasons = [];

//   @override
//   void initState() {
//     super.initState();
//     filteredReasons = List.from(allReasons);
//     _searchController.addListener(_filterList);
//   }

//   void _filterList() {
//     final query = _searchController.text.toLowerCase();
//     setState(() {
//       filteredReasons = allReasons.where((item) {
//         return item['tableName']!.toLowerCase().contains(query) ||
//             item['reason']!.toLowerCase().contains(query) ||
//             item['date']!.toLowerCase().contains(query) ||
//             item['status']!.toLowerCase().contains(query);
//       }).toList();
//     });
//   }

//   void _confirmDeleteItem(Map<String, String> itemToDelete) {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text("Confirm Delete"),
//         content: Text("Are you sure you want to delete this reason?"),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text("Cancel"),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _deleteItem(itemToDelete);
//             },
//             child: Text("Delete", style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }

//   void _deleteItem(Map<String, String> itemToDelete) {
//     setState(() {
//       allReasons.removeWhere((item) => item['id'] == itemToDelete['id']);
//       _filterList();
//     });
//   }

//   void _addNewReason() {
//     final newItem = {
//       'id': DateTime.now().millisecondsSinceEpoch.toString(),
//       'tableName': selectedTable!,
//       'reason': reasonInputController.text.trim(),
//       'date': _getTodayDate(),
//       'status': 'Default',
//     };

//     setState(() {
//       allReasons.add(newItem);
//       _filterList();
//     });
//   }

//   String _getTodayDate() {
//     final now = DateTime.now();
//     return "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
//   }

//   void _openAddReasonDialog() {
//     selectedTable = null;
//     reasonInputController.clear();

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text("Add New Reason", style: TextStyle(fontWeight: FontWeight.bold)),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               DropdownButtonFormField<String>(
//                 isExpanded: true,
//                 value: selectedTable,
//                 hint: Text("Choose Table"),
//                 items: tableOptions.map((table) {
//                   return DropdownMenuItem(value: table, child: Text(table));
//                 }).toList(),
//                 onChanged: (value) {
//                   setState(() {
//                     selectedTable = value;
//                   });
//                 },
//                 decoration: InputDecoration(
//                   labelText: "Table Name",
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               SizedBox(height: 12),
//               TextField(
//                 controller: reasonInputController,
//                 decoration: InputDecoration(
//                   labelText: "Enter Reason",
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text("Cancel"),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               if (selectedTable != null && reasonInputController.text.trim().isNotEmpty) {
//                 _addNewReason();
//                 Navigator.pop(context);
//               }
//             },
//             child: Text("Create"),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     reasonInputController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue.shade800,
//         title: Text("> Settings > Reason Master", style: TextStyle(fontSize: 16)),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           children: [
//             // Search & Create Button
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _searchController,
//                     decoration: InputDecoration(
//                       hintText: "Search",
//                       prefixIcon: Icon(Icons.search),
//                       contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: 10),
//                 ElevatedButton(
//                   onPressed: _openAddReasonDialog,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color.fromARGB(255, 142, 177, 211),
//                     padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//                   ),
//                   child: Text("Create"),
//                 ),
//               ],
//             ),
//             SizedBox(height: 16),

//             // Scrollable Table View
//             Expanded(
//               child: SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: SizedBox(
//                   width: 800,
//                   child: Column(
//                     children: [
//                       Container(
//                         color: const Color.fromARGB(255, 28, 18, 81),
//                         padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
//                         child: Row(
//                           children: const [
//                             Expanded(flex: 2, child: Text("Table", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white))),
//                             Expanded(flex: 2, child: Text("Reason", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white))),
//                             Expanded(child: Text("Date", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white))),
//                             Expanded(child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white))),
//                             SizedBox(width: 40, child: Text("Delete", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white))),
//                           ],
//                         ),
//                       ),
//                       Expanded(
//                         child: filteredReasons.isEmpty
//                             ? Center(
//                                 child: Padding(
//                                   padding: const EdgeInsets.all(32.0),
//                                   child: Text("No results found", style: TextStyle(fontSize: 16, color: Colors.black)),
//                                 ),
//                               )
//                             : ListView.builder(
//                                 itemCount: filteredReasons.length,
//                                 itemBuilder: (context, index) {
//                                   final item = filteredReasons[index];
//                                   return Container(
//                                     padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
//                                     decoration: BoxDecoration(
//                                       border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
//                                     ),
//                                     child: Row(
//                                       children: [
//                                         Expanded(
//                                           flex: 2,
//                                           child: Text(item['tableName']!, style: TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
//                                         ),
//                                         Expanded(
//                                           flex: 2,
//                                           child: Text(item['reason']!, style: TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
//                                         ),
//                                         Expanded(
//                                           child: Text(item['date']!, style: TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
//                                         ),
//                                         Expanded(
//                                           child: Text(item['status']!, style: TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
//                                         ),
//                                         SizedBox(
//                                           width: 40,
//                                           child: IconButton(
//                                             icon: Icon(Icons.delete_outline, size: 18),
//                                             onPressed: () => _confirmDeleteItem(item),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   );
//                                 },
//                               ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';

// App-wide theme colors
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

class ReasonMasterPage extends StatefulWidget {
  const ReasonMasterPage({super.key});

  @override
  _ReasonMasterPageState createState() => _ReasonMasterPageState();
}

class _ReasonMasterPageState extends State<ReasonMasterPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController reasonInputController = TextEditingController();
  String? selectedTable;

  final List<String> tableOptions = [
    'Regularization Reason',
    'Half Day Reason',
    'Comp Off Check In Reason',
    'Week Off Check In Reason',
    'Leave Check In Reason',
    'Check Out Early Reason',
    'Permission Reason',
  ];

  final List<Map<String, String>> allReasons = [
    {
      'id': '1',
      'tableName': 'Regularization Reason',
      'reason': 'Regularization Reason 1',
      'date': '22-01-2025',
      'status': 'Default',
    },
    {
      'id': '2',
      'tableName': 'Half Day Reason',
      'reason': 'Emergency',
      'date': '22-01-2025',
      'status': 'Default',
    },
  ];

  List<Map<String, String>> filteredReasons = [];

  @override
  void initState() {
    super.initState();
    filteredReasons = List.from(allReasons);
    _searchController.addListener(_filterList);
  }

  void _filterList() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredReasons = allReasons.where((item) {
        return item['tableName']!.toLowerCase().contains(query) ||
            item['reason']!.toLowerCase().contains(query) ||
            item['date']!.toLowerCase().contains(query) ||
            item['status']!.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _confirmDeleteItem(Map<String, String> itemToDelete) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this reason?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteItem(itemToDelete);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteItem(Map<String, String> itemToDelete) {
    setState(() {
      allReasons.removeWhere((item) => item['id'] == itemToDelete['id']);
      _filterList();
    });
  }

  void _addNewReason() {
    final newItem = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'tableName': selectedTable!,
      'reason': reasonInputController.text.trim(),
      'date': _getTodayDate(),
      'status': 'Default',
    };

    setState(() {
      allReasons.add(newItem);
      _filterList();
    });
  }

  String _getTodayDate() {
    final now = DateTime.now();
    return "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
  }

  void _openAddReasonDialog() {
    selectedTable = null;
    reasonInputController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Reason", style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: selectedTable,
                hint: const Text("Choose Table"),
                items: tableOptions.map((table) {
                  return DropdownMenuItem(value: table, child: Text(table));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedTable = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: "Table Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonInputController,
                decoration: const InputDecoration(
                  labelText: "Enter Reason",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedTable != null && reasonInputController.text.trim().isNotEmpty) {
                _addNewReason();
                Navigator.pop(context);
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    reasonInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kAppBarColor,
        title: const Text("Reason Master", style: TextStyle(fontSize: 16, color: kTextColor)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
          ),
        ),
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Search & Create Button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search",
                      prefixIcon: const Icon(Icons.search),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _openAddReasonDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kButtonColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  child: const Text("Create", style: TextStyle(color: kTextColor)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Table
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 800,
                  child: Column(
                    children: [
                      Container(
                        color: const Color.fromARGB(255, 101, 81, 147),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        child: Row(
                          children: const [
                            Expanded(flex: 2, child: Text("Table", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white))),
                            Expanded(flex: 2, child: Text("Reason", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white))),
                            Expanded(child: Text("Date", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white))),
                            Expanded(child: Text("Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white))),
                            Expanded(child: Center(child: Text("Delete", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)))),
                          ],
                        ),
                      ),
                      Expanded(
                        child: filteredReasons.isEmpty
                            ? const Center(child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Text("No results found", style: TextStyle(fontSize: 16, color: Colors.black)),
                              ))
                            : ListView.builder(
                                itemCount: filteredReasons.length,
                                itemBuilder: (context, index) {
                                  final item = filteredReasons[index];
                                  return Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                    decoration: BoxDecoration(
                                      border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(flex: 2, child: Text(item['tableName']!, style: const TextStyle(fontSize: 13))),
                                        Expanded(flex: 2, child: Text(item['reason']!, style: const TextStyle(fontSize: 13))),
                                        Expanded(child: Text(item['date']!, style: const TextStyle(fontSize: 13))),
                                        Expanded(child: Text(item['status']!, style: const TextStyle(fontSize: 13))),
                                        Expanded(
                                          child: Center(
                                            child: IconButton(
                                              icon: const Icon(Icons.delete_outline, size: 18),
                                              onPressed: () => _confirmDeleteItem(item),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
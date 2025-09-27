
// // // import 'package:flutter/material.dart';
// // // import 'request_leave_page.dart';
// // // import 'permission_time_page.dart';
// // // import 'over_time_page.dart';
// // // import 'half_day_time_page.dart';
// // // import 'apply_half_day_form_page.dart';

// // // // import 'comp_off_page.dart';

// // // // ✅ Color Constants
// // // const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// // // const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// // // const Color kAppBarColor = Color(0xFF8C6EAF);
// // // const Color kButtonColor = Color(0xFF655193);
// // // const Color kTextColor = Colors.white;

// // // class TypeOfRequestPage extends StatelessWidget {
// // //   const TypeOfRequestPage({super.key});

// // //   final List<Map<String, dynamic>> requestTypes = const [
// // //     {'title': 'Leave Type', 'icon': Icons.calendar_today},
// // //     {'title': 'Permission Time', 'icon': Icons.access_time},
// // //     {'title': 'Over Time', 'icon': Icons.timer},
// // //     {'title': 'Half Day Time', 'icon': Icons.timelapse},
// // //     {'title': 'Comp Off', 'icon': Icons.sync_alt},
// // //   ];

// // //   void _handleNavigation(BuildContext context, String title) {
// // //   if (title == 'Leave Type') {
// // //     showModalBottomSheet(
// // //       context: context,
// // //       isScrollControlled: true,
// // //       backgroundColor: Colors.transparent,
// // //       builder: (_) => const RequestLeavePage(),
// // //     );
// // //   } else if (title == 'Permission Time') {
// // //     showModalBottomSheet(
// // //       context: context,
// // //       isScrollControlled: true,
// // //       backgroundColor: Colors.transparent,
// // //       builder: (_) => const PermissionTimePage(isPopup: false), // full screen
// // //     );
// // //   } else if (title == 'Over Time') {
// // //     showModalBottomSheet(
// // //       context: context,
// // //       isScrollControlled: true,
// // //       backgroundColor: Colors.transparent,
// // //       builder: (_) => const OverTimePage(isPopup: false), // full screen
// // //     );
// // //   } else if (title == 'Half Day Time') {
// // //     showModalBottomSheet(
// // //       context: context,
// // //       isScrollControlled: true,
// // //       backgroundColor: Colors.transparent,
// // //       builder: (_) => const HalfDayTimePage(
// // //         isPopup: false,
// // //         totalHalfDays: 8,
// // //         takenHalfDays: 4,
// // //         status: "Available",
// // //       ),
// // //     );
// // //   } else if (title == 'Comp Off') {
// // //     Navigator.push(
// // //       context,
// // //       MaterialPageRoute(builder: (_)=> const ApplyHalfDayForm()),
// // //     );
// // //   }

// // // //    } else {
// // // //     ScaffoldMessenger.of(context).showSnackBar(
// // // //       SnackBar(content: Text('$title clicked - not connected')),
// // // //     );
// // // //   }
// // // }


// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: const Text("Type Of Requests"),
// // //         backgroundColor: kAppBarColor,
// // //         centerTitle: true,
// // //       ),
// // //       body: Container(
// // //         decoration: const BoxDecoration(
// // //           gradient: LinearGradient(
// // //             begin: Alignment.topCenter,
// // //             end: Alignment.bottomCenter,
// // //             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
// // //           ),
// // //         ),
// // //         child: Padding(
// // //           padding: const EdgeInsets.all(16.0),
// // //           child: GridView.builder(
// // //             itemCount: requestTypes.length,
// // //             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
// // //               crossAxisCount: 2,
// // //               crossAxisSpacing: 12,
// // //               mainAxisSpacing: 12,
// // //               childAspectRatio: 1.2,
// // //             ),
// // //             itemBuilder: (context, index) {
// // //               final item = requestTypes[index];
// // //               return GestureDetector(
// // //                 onTap: () => _handleNavigation(context, item['title']),
// // //                 child: Container(
// // //                   decoration: BoxDecoration(
// // //                     color: kPrimaryBackgroundTop,
// // //                     borderRadius: BorderRadius.circular(12),
// // //                     boxShadow: const [
// // //                       BoxShadow(
// // //                         color: Colors.black12,
// // //                         blurRadius: 4,
// // //                         offset: Offset(2, 2),
// // //                       ),
// // //                     ],
// // //                   ),
// // //                   child: Column(
// // //                     mainAxisAlignment: MainAxisAlignment.center,
// // //                     children: [
// // //                       Icon(item['icon'], size: 40, color: kButtonColor),
// // //                       const SizedBox(height: 10),
// // //                       Text(
// // //                         item['title'],
// // //                         style: const TextStyle(
// // //                           fontSize: 16,
// // //                           fontWeight: FontWeight.w600,
// // //                           color: kAppBarColor,
// // //                         ),
// // //                       ),
// // //                     ],
// // //                   ),
// // //                 ),
// // //               );
// // //             },
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// // import 'package:flutter/material.dart';
// // import 'request_leave_page.dart';
// // import 'permission_time_page.dart';
// // import 'over_time_page.dart';
// // import 'half_day_time_page.dart';
// // import 'apply_half_day_form_page.dart';

// // // ✅ Color Constants
// // const Color kPrimaryBackgroundTop = Color(0xFFF3E5F5); // very light violet
// // const Color kPrimaryBackgroundBottom = Color(0xFFE1BEE7); // soft lavender
// // const Color kAppBarColor = Color(0xFF8C6EAF);
// // const Color kButtonColor = Color(0xFF655193);
// // const Color kTextColor = Colors.white;

// // class TypeOfRequestPage extends StatelessWidget {
// //   const TypeOfRequestPage({super.key});

// //   final List<Map<String, dynamic>> requestTypes = const [
// //     {'title': 'Leave Type', 'icon': Icons.calendar_today},
// //     {'title': 'Permission Time', 'icon': Icons.access_time},
// //     {'title': 'Over Time', 'icon': Icons.timer},
// //     {'title': 'Half Day Time', 'icon': Icons.timelapse},
// //     {'title': 'Comp Off', 'icon': Icons.sync_alt},
// //   ];

// //   void _handleNavigation(BuildContext context, String title) {
// //     if (title == 'Leave Type') {
// //       showModalBottomSheet(
// //         context: context,
// //         isScrollControlled: true,
// //         backgroundColor: Colors.transparent,
// //         builder: (_) => const RequestLeavePage(),
// //       );
// //     } else if (title == 'Permission Time') {
// //       showModalBottomSheet(
// //         context: context,
// //         isScrollControlled: true,
// //         backgroundColor: Colors.transparent,
// //         builder: (_) => const PermissionTimePage(isPopup: false),
// //       );
// //     } else if (title == 'Over Time') {
// //       showModalBottomSheet(
// //         context: context,
// //         isScrollControlled: true,
// //         backgroundColor: Colors.transparent,
// //         builder: (_) => const OverTimePage(isPopup: false),
// //       );
// //     } else if (title == 'Half Day Time') {
// //       showModalBottomSheet(
// //         context: context,
// //         isScrollControlled: true,
// //         backgroundColor: Colors.transparent,
// //         builder: (_) => const HalfDayTimePage(
// //           isPopup: false,
// //           totalHalfDays: 8,
// //           takenHalfDays: 4,
// //           status: "Available",
// //         ),
// //       );
// //     } else if (title == 'Comp Off') {
// //       Navigator.push(
// //         context,
// //         MaterialPageRoute(builder: (_) => const ApplyHalfDayForm()),
// //       );
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text("Type Of Requests", style: TextStyle(fontSize: 18)),
// //         backgroundColor: kAppBarColor,
// //         centerTitle: true,
// //       ),
// //       body: Container(
// //         decoration: const BoxDecoration(
// //           gradient: LinearGradient(
// //             begin: Alignment.topCenter,
// //             end: Alignment.bottomCenter,
// //             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
// //           ),
// //         ),
// //         child: Padding(
// //           padding: const EdgeInsets.all(12.0),
// //           child: GridView.builder(
// //             itemCount: requestTypes.length,
// //             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
// //               crossAxisCount: 2, // ⬅ smaller boxes using 3 columns
// //               crossAxisSpacing: 10,
// //               mainAxisSpacing: 10,
// //               childAspectRatio: 0.9, // adjust tile height
// //             ),
// //             itemBuilder: (context, index) {
// //               final item = requestTypes[index];
// //               return GestureDetector(
// //                 onTap: () => _handleNavigation(context, item['title']),
// //                 child: Container(
// //                   decoration: BoxDecoration(
// //                     color: kPrimaryBackgroundTop,
// //                     borderRadius: BorderRadius.circular(10),
// //                     boxShadow: const [
// //                       BoxShadow(
// //                         color: Colors.black12,
// //                         blurRadius: 4,
// //                         offset: Offset(2, 2),
// //                       ),
// //                     ],
// //                   ),
// //                   padding: const EdgeInsets.symmetric(vertical: 12),
// //                   child: Column(
// //                     mainAxisAlignment: MainAxisAlignment.center,
// //                     children: [
// //                       Icon(item['icon'], size: 28, color: kButtonColor),
// //                       const SizedBox(height: 8),
// //                       Text(
// //                         item['title'],
// //                         textAlign: TextAlign.center,
// //                         style: const TextStyle(
// //                           fontSize: 12, // ⬅ smaller font
// //                           fontWeight: FontWeight.w600,
// //                           color: kAppBarColor,
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               );
// //             },
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// import 'package:flutter/material.dart';
// import 'request_leave_page.dart';
// import 'permission_time_page.dart';
// import 'over_time_page.dart';
// import 'half_day_time_page.dart';
// import 'apply_half_day_form_page.dart';

// // ✅ Color Constants
// const Color kPrimaryBackgroundTop = Color(0xFFF3E5F5); // Light violet
// const Color kPrimaryBackgroundBottom = Color(0xFFE1BEE7); // Soft lavender
// const Color kAppBarColor = Color(0xFF8C6EAF);
// const Color kButtonColor = Color(0xFF655193);
// const Color kTextColor = Colors.white;

// class TypeOfRequestPage extends StatelessWidget {
//   const TypeOfRequestPage({super.key});

//   final List<Map<String, dynamic>> requestTypes = const [
//     {'title': 'Leave Type', 'icon': Icons.calendar_today},
//     {'title': 'Permission Time', 'icon': Icons.access_time},
//     {'title': 'Over Time', 'icon': Icons.timer},
//     {'title': 'Half Day Time', 'icon': Icons.timelapse},
//     {'title': 'Comp Off', 'icon': Icons.sync_alt},
//   ];

//   void _handleNavigation(BuildContext context, String title) {
//     if (title == 'Leave Type') {
//       showModalBottomSheet(
//         context: context,
//         isScrollControlled: true,
//         backgroundColor: Colors.transparent,
//         builder: (_) => const RequestLeavePage(),
//       );
//     } else if (title == 'Permission Time') {
//       showModalBottomSheet(
//         context: context,
//         isScrollControlled: true,
//         backgroundColor: Colors.transparent,
//         builder: (_) => const PermissionTimePage(isPopup: false),
//       );
//     } else if (title == 'Over Time') {
//       showModalBottomSheet(
//         context: context,
//         isScrollControlled: true,
//         backgroundColor: Colors.transparent,
//         builder: (_) => const OverTimePage(isPopup: false),
//       );
//     } else if (title == 'Half Day Time') {
//       showModalBottomSheet(
//         context: context,
//         isScrollControlled: true,
//         backgroundColor: Colors.transparent,
//         builder: (_) => const HalfDayTimePage(
//           isPopup: false,
//           totalHalfDays: 8,
//           takenHalfDays: 4,
//           status: "Available",
//         ),
//       );
//     } else if (title == 'Comp Off') {
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (_) => const ApplyHalfDayForm()),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Type Of Requests", style: TextStyle(fontSize: 18)),
//         backgroundColor: kAppBarColor,
//         centerTitle: true,
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
//           ),
//         ),
//         child: Center(
//           child: Wrap(
//             spacing: 16,
//             runSpacing: 16,
//             alignment: WrapAlignment.center,
//             children: requestTypes.map((item) {
//               return GestureDetector(
//                 onTap: () => _handleNavigation(context, item['title']),
//                 child: Container(
//                   height: 100,
//                   width: 100,
//                   decoration: BoxDecoration(
//                     color: kPrimaryBackgroundTop,
//                     borderRadius: BorderRadius.circular(12),
//                     boxShadow: const [
//                       BoxShadow(
//                         color: Colors.black12,
//                         blurRadius: 4,
//                         offset: Offset(2, 2),
//                       ),
//                     ],
//                   ),
//                   padding: const EdgeInsets.all(8),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(item['icon'], size: 28, color: kButtonColor),
//                       const SizedBox(height: 6),
//                       Text(
//                         item['title'],
//                         textAlign: TextAlign.center,
//                         style: const TextStyle(
//                           fontSize: 11,
//                           fontWeight: FontWeight.w600,
//                           color: kAppBarColor,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             }).toList(),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:serv_app/Pagesusers/apply_leave_form_page.dart';
import 'request_leave_page.dart';
import 'permission_time_page.dart';
import 'over_time_page.dart';
import 'half_day_time_page.dart';

// Theme colors
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;
const Color kIconColor = Color(0xFF3D0066);

class TypeOfRequestPage extends StatelessWidget {
  const TypeOfRequestPage({super.key});

  final List<Map<String, dynamic>> requestTypes = const [
    {'title': 'Leave Type', 'icon': Icons.calendar_today},
    {'title': 'Permission Time', 'icon': Icons.access_time},
    {'title': 'Over Time', 'icon': Icons.timer},
    {'title': 'Half Day Time', 'icon': Icons.timelapse},
    {'title': 'Comp Off', 'icon': Icons.sync_alt},
  ];

  void _handleNavigation(BuildContext context, String title) {
    if (title == 'Leave Type') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const RequestLeavePage(),
      );
    } else if (title == 'Permission Time') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const PermissionTimePage(isPopup: false),
      );
    } else if (title == 'Over Time') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const OverTimePage(isPopup: false),
      );
    } else if (title == 'Half Day Time') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const HalfDayTimePage(
          isPopup: false,
          totalHalfDays: 8,
          takenHalfDays: 4,
          status: "Available",
        ),
      );
    } else if (title == 'Comp Off') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ApplyHalfDayForm()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Type Of Requests", style: TextStyle(fontSize: 18)),
        backgroundColor: kAppBarColor,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
          ),
        ),
        alignment: Alignment.topCenter, // ❗️Align tiles to top
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: requestTypes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1, // Matches myserv_page.dart
            ),
            itemBuilder: (context, index) {
              final item = requestTypes[index];
              return GestureDetector(
                onTap: () => _handleNavigation(context, item['title']),
                child: Card(
                  color: kAppBarColor.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 36,
                          width: 36,
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.mode(
                              kIconColor,
                              BlendMode.srcIn,
                            ),
                            child: Icon(item['icon'], size: 28),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['title'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: kTextColor,
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
      ),
    );
  }
}

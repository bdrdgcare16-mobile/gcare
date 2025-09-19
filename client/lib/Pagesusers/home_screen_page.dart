// import 'package:flutter/material.dart';
// import 'attendance_page.dart';
// import 'profile_page.dart';
// import 'package:serv_app/Pagesusers/myserv_page.dart'; // ✅ MyServPage

// // App Colors
// const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// const Color kAppBarColor = Color(0xFF8C6EAF);
// const Color kButtonColor = Color(0xFF655193);
// const Color kTextColor = Colors.white;

// class HomeScreen extends StatelessWidget {
//   final String userName;

//   const HomeScreen({super.key, required this.userName});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         height: double.infinity,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
//           ),
//         ),
//         child: SafeArea(
//           child: LayoutBuilder(
//             builder: (context, constraints) {
//               return SingleChildScrollView(
//                 child: ConstrainedBox(
//                   constraints: BoxConstraints(minHeight: constraints.maxHeight),
//                   child: IntrinsicHeight(
//                     child: Column(
//                       children: [
//                         // Top bar
//                         Padding(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 16,
//                             vertical: 8,
//                           ),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               const Text(
//                                 'SERV',
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 23,
//                                   color: kAppBarColor,
//                                 ),
//                               ),
//                               Row(
//                                 children: const [
//                                   Icon(
//                                     Icons.location_on,
//                                     color: Color.fromARGB(255, 12, 8, 8),
//                                   ),
//                                   SizedBox(width: 22),
//                                   Icon(
//                                     Icons.warning,
//                                     color: Color.fromARGB(255, 12, 8, 8),
//                                   ),
//                                   SizedBox(width: 22),
//                                   Icon(
//                                     Icons.person,
//                                     color: Color.fromARGB(255, 12, 8, 8),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                         Container(height: 3, color: kAppBarColor),
//                         const SizedBox(height: 16),

//                         Center(
//                           child: Text(
//                             'Hello, $userName',
//                             style: const TextStyle(
//                               color: Color.fromARGB(255, 22, 20, 20),
//                               fontWeight: FontWeight.w600,
//                               fontSize: 15,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 8),

//                         const Center(
//                           child: Text(
//                             'With SERV, You Deserve the Best',
//                             style: TextStyle(
//                               color: kAppBarColor,
//                               fontSize: 14,
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                         ),

//                         const SizedBox(height: 8),

//                         SizedBox(
//                           height: 200,
//                           width: 200,
//                           child: Image.asset(
//                             'assets/images/attendance-management.png',
//                           ),
//                         ),

//                         const SizedBox(height: 3),

//                         // ✅ Attendance and My Serv Buttons
//                         Padding(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 20,
//                           ), // Reduced padding
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                             children: [
//                               // Attendance Button
//                               GestureDetector(
//                                 onTap: () {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (_) => AttendanceScreen(employeeDocId: '',),
//                                     ),
//                                   );
//                                 },
//                                 child: Container(
//                                   width: 100,
//                                   height: 100,
//                                   decoration: BoxDecoration(
//                                     color: kPrimaryBackgroundBottom,
//                                     borderRadius: BorderRadius.circular(18),
//                                     boxShadow: const [
//                                       BoxShadow(
//                                         color: Colors.black12,
//                                         blurRadius: 5,
//                                         offset: Offset(2, 2),
//                                       ),
//                                     ],
//                                   ),
//                                   child: Column(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: const [
//                                       Icon(
//                                         Icons.calendar_month,
//                                         size: 50,
//                                         color: kAppBarColor,
//                                       ),
//                                       SizedBox(height: 8),
//                                       Text(
//                                         'Attendance',
//                                         style: TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors.black,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),

//                               // ✅ My Serv Button (updated)
//                               GestureDetector(
//                                 onTap: () {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (_) => const MyServPage(),
//                                     ),
//                                   );
//                                 },
//                                 child: Container(
//                                   width: 100,
//                                   height: 100,
//                                   decoration: BoxDecoration(
//                                     color:
//                                         kPrimaryBackgroundBottom, // matched Attendance color
//                                     borderRadius: BorderRadius.circular(18),
//                                     boxShadow: const [
//                                       BoxShadow(
//                                         color: Colors.black12,
//                                         blurRadius: 5,
//                                         offset: Offset(2, 2),
//                                       ),
//                                     ],
//                                   ),
//                                   child: Column(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: const [
//                                       Icon(
//                                         Icons.handshake,
//                                         size: 50,
//                                         color: kAppBarColor,
//                                       ),
//                                       SizedBox(height: 8),
//                                       Text(
//                                         'My Serv',
//                                         style: TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors
//                                               .black, // text color updated
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),

//                         const Spacer(),
//                       ],
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ),

//       // ✅ Bottom Navigation Bar
//       bottomNavigationBar: Container(
//         height: 50,
//         decoration: const BoxDecoration(
//           color: kAppBarColor,
//           // borderRadius: BorderRadius.only(
//           //   topLeft: Radius.circular(26),
//           //   topRight: Radius.circular(26),
//           // ),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: [
//             BottomNavItem(icon: Icons.home, label: 'Home'),
//             BottomNavItem(
//               icon: Icons.person,
//               label: 'Profile',
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => const ProfilePage(userData: {}),
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class BottomNavItem extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final VoidCallback? onTap;

//   const BottomNavItem({
//     super.key,
//     required this.icon,
//     required this.label,
//     this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, color: kTextColor, size: 18),
//           Text(
//             label,
//             style: const TextStyle(
//               color: kTextColor,
//               fontWeight: FontWeight.w600,
//               fontSize: 9,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'attendance_page.dart';
import 'profile_page.dart';
import 'package:serv_app/Pagesusers/myserv_page.dart';

// App Colors
const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor = Color(0xFF8C6EAF);
const Color kButtonColor = Color(0xFF655193);
const Color kTextColor = Colors.white;

class HomeScreen extends StatelessWidget {
  final String userName;
  final String employeeDocId;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.employeeDocId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // Top bar
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'SERV',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 23,
                                  color: kAppBarColor,
                                ),
                              ),
                              Row(
                                children: const [
                                  Icon(Icons.location_on, color: Colors.black),
                                  SizedBox(width: 22),
                                  Icon(Icons.warning, color: Colors.black),
                                  SizedBox(width: 22),
                                  Icon(Icons.person, color: Colors.black),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(height: 3, color: kAppBarColor),
                        const SizedBox(height: 16),

                        Center(
                          child: Text(
                            'Hello, $userName',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        const Center(
                          child: Text(
                            'With SERV, You Deserve the Best',
                            style: TextStyle(
                              color: kAppBarColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        SizedBox(
                          height: 200,
                          width: 200,
                          child: Image.asset(
                              'assets/images/attendance-management.png'),
                        ),
                        const SizedBox(height: 3),

                        // Attendance and My Serv buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Attendance
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AttendanceScreen(
                                        employeeDocId: employeeDocId,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: kPrimaryBackgroundBottom,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 5,
                                        offset: Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.calendar_month,
                                          size: 50, color: kAppBarColor),
                                      SizedBox(height: 8),
                                      Text('Attendance',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black)),
                                    ],
                                  ),
                                ),
                              ),

                              // My Serv
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const MyServPage()),
                                  );
                                },
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: kPrimaryBackgroundBottom,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 5,
                                        offset: Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.handshake,
                                          size: 50, color: kAppBarColor),
                                      SizedBox(height: 8),
                                      Text('My Serv',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 50,
        decoration: const BoxDecoration(color: kAppBarColor),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const BottomNavItem(icon: Icons.home, label: 'Home'),
            BottomNavItem(
              icon: Icons.person,
              label: 'Profile',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(userData: {
                      'name': userName,
                      'id': employeeDocId,
                    }),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const BottomNavItem({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: kTextColor, size: 18),
          Text(
            label,
            style: const TextStyle(
              color: kTextColor,
              fontWeight: FontWeight.w600,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

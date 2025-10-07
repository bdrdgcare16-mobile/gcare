// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'attendance_page.dart';
// import 'profile_page.dart';
// import 'package:serv_app/Pagesusers/myserv_page.dart';

// // App Colors
// const Color kPrimaryBackgroundTop = Color(0xFFFFFFFF);
// const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
// const Color kAppBarColor = Color(0xFF8C6EAF);
// const Color kButtonColor = Color(0xFF655193);
// const Color kTextColor = Colors.white;

// class HomeScreen extends StatelessWidget {
//   final String userName;
//   final String employeeDocId;

//   const HomeScreen({
//     super.key,
//     required this.userName,
//     required this.employeeDocId,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final overlay = SystemUiOverlayStyle(
//       statusBarColor: Colors.transparent,
//       statusBarIconBrightness: Brightness.dark,
//       systemNavigationBarColor: kAppBarColor,
//       systemNavigationBarIconBrightness: Brightness.light,
//     );

//     final size = MediaQuery.of(context).size;
//     final isShort = size.height < 650;

//     return AnnotatedRegion<SystemUiOverlayStyle>(
//       value: overlay,
//       child: Scaffold(
//         backgroundColor: Colors.transparent,
//         resizeToAvoidBottomInset: false,
//         body: Stack(
//           children: [
//             // ======= Enhanced Background (soft shapes) =======
//             Container(
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
//                 ),
//               ),
//             ),
//             Positioned(
//               top: -80,
//               left: -60,
//               child: _BlobCircle(
//                 diameter: 220,
//                 color: kAppBarColor.withOpacity(0.10),
//               ),
//             ),
//             Positioned(
//               top: 140,
//               right: -70,
//               child: _BlobCircle(
//                 diameter: 180,
//                 color: kButtonColor.withOpacity(0.08),
//               ),
//             ),
//             Positioned(
//               bottom: -60,
//               left: -40,
//               child: _BlobCircle(
//                 diameter: 160,
//                 color: kAppBarColor.withOpacity(0.07),
//               ),
//             ),

//             // ======= Page Content =======
//             SafeArea(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   // ---------- Fixed Header (polished strip) ----------
//                   Padding(
//                     padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.9),
//                         borderRadius: BorderRadius.circular(14),
//                         boxShadow: const [
//                           BoxShadow(
//                             color: Color(0x14000000),
//                             blurRadius: 10,
//                             offset: Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: Row(
//                         children: [
//                           // Logo tighter to top-left
//                           Padding(
//                             padding: const EdgeInsets.only(left: 2),
//                             child: Image.asset(
//                               'assets/images/logobg.png',
//                               height: 54, // visually prominent but compact
//                               width: 148,
//                               fit: BoxFit.contain,
//                               alignment: Alignment.topLeft,
//                             ),
//                           ),
//                           const Spacer(),
//                           const _HeaderIcon(icon: Icons.location_on),
//                           const SizedBox(width: 14),
//                           const _HeaderIcon(icon: Icons.warning),
//                           const SizedBox(width: 14),
//                           const _HeaderIcon(icon: Icons.person),
//                         ],
//                       ),
//                     ),
//                   ),

//                   // Divider line (thin)
//                   Container(height: 2, color: kAppBarColor.withOpacity(0.85)),

//                   // ---------- Main Content ----------
//                   Expanded(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.start,
//                       children: [
//                         const SizedBox(height: 14),

//                         // Greeting — animated appear
//                         _FadeSlide(
//                           delayMs: 50,
//                           child: Text(
//                             'Hello, $userName',
//                             style: const TextStyle(
//                               color: Colors.black,
//                               fontWeight: FontWeight.w600,
//                               fontSize: 16,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 6),

//                         // Tagline — animated appear
//                         _FadeSlide(
//                           delayMs: 120,
//                           child: const Text(
//                             'With SERV, You Deserve the Best',
//                             style: TextStyle(
//                               color: kAppBarColor,
//                               fontSize: 14,
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 12),

//                         // Illustration in a card for depth
//                         _FadeSlide(
//                           delayMs: 200,
//                           child: Container(
//                             width: size.width * 0.78,
//                             height: isShort ? 230 : 300,
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(20),
//                               boxShadow: const [
//                                 BoxShadow(
//                                   color: Color(0x19000000),
//                                   blurRadius: 16,
//                                   offset: Offset(0, 8),
//                                 ),
//                               ],
//                             ),
//                             clipBehavior: Clip.antiAlias,
//                             child: Padding(
//                               padding: const EdgeInsets.all(12),
//                               child: Image.asset(
//                                 'assets/images/attendance-management.png',
//                                 fit: BoxFit.contain,
//                               ),
//                             ),
//                           ),
//                         ),

//                         const SizedBox(height: 28),

//                         // Tiles row — animated
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 18),
//                           child: _FadeSlide(
//                             delayMs: 280,
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                               children: [
//                                 _HomeTile(
//                                   icon: Icons.calendar_month,
//                                   label: 'Attendance',
//                                   onTap: () {
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (_) => AttendanceScreen(
//                                           employeeDocId: employeeDocId,
//                                         ),
//                                       ),
//                                     );
//                                   },
//                                 ),
//                                 _HomeTile(
//                                   icon: Icons.handshake,
//                                   label: 'My Serv',
//                                   onTap: () {
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (_) => const MyServPage(),
//                                       ),
//                                     );
//                                   },
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),

//                         // Spacer to keep distance from footer
//                         SizedBox(height: isShort ? 8 : 14),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),

//         // ---------- Footer ----------
//         bottomNavigationBar: SafeArea(
//           top: false,
//           child: Container(
//             height: 50,
//             decoration: const BoxDecoration(color: kAppBarColor),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 const BottomNavItem(icon: Icons.home, label: 'Home'),
//                 BottomNavItem(
//                   icon: Icons.person,
//                   label: 'Profile',
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => ProfilePage(userData: {
//                           'name': userName,
//                           'id': employeeDocId,
//                         }),
//                       ),
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ---------- Decorative soft circle ----------
// class _BlobCircle extends StatelessWidget {
//   final double diameter;
//   final Color color;
//   const _BlobCircle({required this.diameter, required this.color});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: diameter,
//       height: diameter,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         color: color,
//         boxShadow: [
//           BoxShadow(
//             color: color.withOpacity(0.35),
//             blurRadius: 40,
//             spreadRadius: 6,
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ---------- Header icon chip ----------
// class _HeaderIcon extends StatelessWidget {
//   final IconData icon;
//   const _HeaderIcon({required this.icon});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 34,
//       height: 34,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         boxShadow: const [
//           BoxShadow(
//             color: Color(0x14000000),
//             blurRadius: 8,
//             offset: Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Icon(icon, color: Colors.black87, size: 18),
//     );
//   }
// }

// // ---------- Fade & slight slide-in (stateless utility) ----------
// class _FadeSlide extends StatelessWidget {
//   final Widget child;
//   final int delayMs;
//   const _FadeSlide({required this.child, this.delayMs = 0});

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<void>(
//       future: Future.delayed(Duration(milliseconds: delayMs)),
//       builder: (context, snapshot) {
//         return TweenAnimationBuilder<double>(
//           tween: Tween(begin: 0.0, end: 1.0),
//           duration: const Duration(milliseconds: 480),
//           curve: Curves.easeOutCubic,
//           builder: (context, value, _) {
//             return Opacity(
//               opacity: value,
//               child: Transform.translate(
//                 offset: Offset(0, (1 - value) * 12),
//                 child: child,
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }

// // ---------- Small square tile widget ----------
// class _HomeTile extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final VoidCallback onTap;

//   const _HomeTile({
//     required this.icon,
//     required this.label,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final tileW = size.width * 0.36;
//     final tileH = size.height < 650 ? 98.0 : 112.0;

//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(20),
//         splashColor: kAppBarColor.withOpacity(0.15),
//         highlightColor: kButtonColor.withOpacity(0.10),
//         child: Ink(
//           width: tileW,
//           height: tileH,
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 kPrimaryBackgroundBottom.withOpacity(0.95),
//                 kPrimaryBackgroundBottom.withOpacity(0.80),
//               ],
//             ),
//             borderRadius: BorderRadius.circular(20),
//             boxShadow: const [
//               BoxShadow(
//                 color: Color(0x1A000000),
//                 blurRadius: 10,
//                 offset: Offset(0, 6),
//               ),
//             ],
//             border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(icon, size: 44, color: kAppBarColor),
//               const SizedBox(height: 8),
//               Text(
//                 label,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.w700,
//                   color: Colors.black,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ---------- Footer item ----------
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
//       behavior: HitTestBehavior.opaque,
//       child: SizedBox(
//         width: 86,
//         height: 50,
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, color: kTextColor, size: 18),
//             const SizedBox(height: 2),
//             Text(
//               label,
//               style: const TextStyle(
//                 color: kTextColor,
//                 fontWeight: FontWeight.w600,
//                 fontSize: 10,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: kAppBarColor,
      systemNavigationBarIconBrightness: Brightness.light,
    );

    final size = MediaQuery.of(context).size;
    final isShort = size.height < 650;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // ======= Enhanced Background (soft shapes) =======
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [kPrimaryBackgroundTop, kPrimaryBackgroundBottom],
                ),
              ),
            ),
            Positioned(
              top: -80,
              left: -60,
              child: _BlobCircle(
                diameter: 220,
                color: kAppBarColor.withOpacity(0.10),
              ),
            ),
            Positioned(
              top: 140,
              right: -70,
              child: _BlobCircle(
                diameter: 180,
                color: kButtonColor.withOpacity(0.08),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -40,
              child: _BlobCircle(
                diameter: 160,
                color: kAppBarColor.withOpacity(0.07),
              ),
            ),

            // ======= Page Content =======
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---------- Fixed Header (polished strip) ----------
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Logo tighter to top-left
                          Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Image.asset(
                              'assets/images/logobg.png',
                              height: 54, // visually prominent but compact
                              width: 148,
                              fit: BoxFit.contain,
                              alignment: Alignment.topLeft,
                            ),
                          ),
                          const Spacer(),
                          const _HeaderIcon(icon: Icons.location_on),
                          const SizedBox(width: 14),
                          const _HeaderIcon(icon: Icons.warning),
                          const SizedBox(width: 14),
                          const _HeaderIcon(icon: Icons.person),
                        ],
                      ),
                    ),
                  ),

                  // Divider line (thin)
                  Container(height: 2, color: kAppBarColor.withOpacity(0.85)),

                  // ---------- Main Content ----------
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 14),

                        // Greeting — animated appear
                        _FadeSlide(
                          delayMs: 50,
                          child: Text(
                            'Hello, $userName',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Tagline — animated appear
                        _FadeSlide(
                          delayMs: 120,
                          child: const Text(
                            'With SERV, You Deserve the Best',
                            style: TextStyle(
                              color: kAppBarColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Illustration — DIRECT on background (white box removed)
                        _FadeSlide(
                          delayMs: 200,
                          child: SizedBox(
                            width: size.width * 0.78,
                            height: isShort ? 230 : 300,
                            child: Image.asset(
                              'assets/images/attendance-management.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Tiles row — animated
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: _FadeSlide(
                            delayMs: 280,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _HomeTile(
                                  icon: Icons.calendar_month,
                                  label: 'Attendance',
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
                                ),
                                _HomeTile(
                                  icon: Icons.handshake,
                                  label: 'My Serv',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const MyServPage(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Spacer to keep distance from footer
                        SizedBox(height: isShort ? 8 : 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // ---------- Footer ----------
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
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
        ),
      ),
    );
  }
}

// ---------- Decorative soft circle ----------
class _BlobCircle extends StatelessWidget {
  final double diameter;
  final Color color;
  const _BlobCircle({required this.diameter, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 40,
            spreadRadius: 6,
          ),
        ],
      ),
    );
  }
}

// ---------- Header icon chip ----------
class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  const _HeaderIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.black87, size: 18),
    );
  }
}

// ---------- Fade & slight slide-in (stateless utility) ----------
class _FadeSlide extends StatelessWidget {
  final Widget child;
  final int delayMs;
  const _FadeSlide({required this.child, this.delayMs = 0});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: Future.delayed(Duration(milliseconds: delayMs)),
      builder: (context, snapshot) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 480),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 12),
                child: child,
              ),
            );
          },
        );
      },
    );
  }
}

// ---------- Small square tile widget ----------
class _HomeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HomeTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final tileW = size.width * 0.36;
    final tileH = size.height < 650 ? 98.0 : 112.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: kAppBarColor.withOpacity(0.15),
        highlightColor: kButtonColor.withOpacity(0.10),
        child: Ink(
          width: tileW,
          height: tileH,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                kPrimaryBackgroundBottom.withOpacity(0.95),
                kPrimaryBackgroundBottom.withOpacity(0.80),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 44, color: kAppBarColor),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Footer item ----------
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
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 86,
        height: 50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: kTextColor, size: 18),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: kTextColor,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

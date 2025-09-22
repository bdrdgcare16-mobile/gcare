// import 'package:flutter/material.dart';
// import 'login_page.dart'; // make sure this path is correct

// class LogOutPage extends StatelessWidget {
//   const LogOutPage({super.key});

//   void _handleLogout(BuildContext context) {
//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(builder: (context) => const LoginPage()),
//       (route) => false,
//     );

//     Future.delayed(Duration(milliseconds: 100), () {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Logged out successfully")),
//       );
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.cyanAccent,
//         title: const Text(
//           'Log Out',
//           style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
//         ),
//         iconTheme: const IconThemeData(color: Colors.black),
//         centerTitle: true,
//       ),
//       body: Center(
//         child: Container(
//           margin: const EdgeInsets.all(24),
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(color: Colors.grey.shade300),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text(
//                 'Log  Out?',
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//               ),
//               const SizedBox(height: 10),
//               const Text(
//                 'Are you sure you want to logout?',
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 20),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   OutlinedButton(
//                     onPressed: () => Navigator.pop(context),
//                     style: OutlinedButton.styleFrom(
//                       backgroundColor: Colors.grey.shade200,
//                       foregroundColor: Colors.black,
//                     ),
//                     child: const Text("CANCEL"),
//                   ),
//                   ElevatedButton(
//                     onPressed: () => _handleLogout(context),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.indigo.shade300,
//                       foregroundColor: Colors.white,
//                     ),
//                     child: const Text("LOG OUT"),
//                   ),
//                 ],
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'login_page.dart'; // make sure this path is correct

// Theme color constants
const Color kPrimaryBackgroundTop    = Color(0xFFFFFFFF);
const Color kPrimaryBackgroundBottom = Color(0xFFD1C4E9);
const Color kAppBarColor             = Color(0xFF8C6EAF);
const Color kButtonColor             = Color(0xFF655193);
const Color kTextColor               = Colors.white;

class LogOutPage extends StatelessWidget {
  const LogOutPage({super.key});

  void _handleLogout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Logged out successfully")),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar stays at the top
      appBar: AppBar(
        backgroundColor: kAppBarColor,
        title: const Text(
          'Log Out',
          style: TextStyle(
            color: kTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: kTextColor),
        centerTitle: true,
        elevation: 0,
      ),
      // Body with gradient background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              kPrimaryBackgroundTop,
              kPrimaryBackgroundBottom,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kPrimaryBackgroundTop,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Log Out?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Are you sure you want to logout?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: kPrimaryBackgroundTop,
                          foregroundColor: kAppBarColor,
                          side: BorderSide(color: kAppBarColor),
                        ),
                        child: const Text("CANCEL"),
                      ),
                      ElevatedButton(
                        onPressed: () => _handleLogout(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kButtonColor,
                          foregroundColor: kTextColor,
                        ),
                        child: const Text("LOG OUT"),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

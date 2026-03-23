import 'package:serv_app/main_common.dart';
import 'firebase_options_dev.dart';

Future<void> main() async {
  await startApp(
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    environmentName: 'DEV',
  );
}
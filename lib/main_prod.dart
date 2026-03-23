import 'package:serv_app/main_common.dart';
import 'firebase_options_prod.dart';

Future<void> main() async {
  await startApp(
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    environmentName: 'PROD',
  );
}
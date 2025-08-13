import 'package:postgres/postgres.dart';

final connection = PostgreSQLConnection(
  'localhost', // or your DB host
  5432,        // default port
  'myappdb',   // your database name
  username: 'myappuser',
  password: 'mypassword',
);

Future<void> connectDb() async {
  await connection.open();
}

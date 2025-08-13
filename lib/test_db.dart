import 'db.dart';

void main() async {
  try {
    await connectDb();
    // Connected to PostgreSQL successfully!
    await connection.close();
  } catch (e) {
    // Connection failed: $e
  }
}

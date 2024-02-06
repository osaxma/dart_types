import 'package:dart_types/src/commands.dart';

void main(List<String> args) async {
  try {
    final runner = Runner();
    await runner.run(args);
  } catch (e) {
    print('ERROR: $e');
  }
}

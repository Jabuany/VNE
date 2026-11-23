import 'package:flutter/widgets.dart';

void main() {
  runApp(const VneApp());
}

class VneApp extends StatelessWidget {
  const VneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'VNE',
      color: Color(0xff171a21),
      debugShowCheckedModeBanner: false,
      builder: (context, child) => const ColoredBox(
        color: Color(0xff171a21),
        child: SafeArea(
          child: Center(
            child: Text(
              'VNE',
              style: TextStyle(color: Color(0xfff2f3f5), fontSize: 32),
            ),
          ),
        ),
      ),
    );
  }
}

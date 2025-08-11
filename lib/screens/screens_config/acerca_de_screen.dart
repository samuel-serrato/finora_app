import 'package:flutter/material.dart';

class AcercaDeScreen extends StatelessWidget {
  const AcercaDeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acerca de'),
      ),
      body: const Center(
        child: Text(
          'Aquí irá la información sobre la aplicación.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '/ui/screens/cache_convert_screen.dart';
import '/ui/screens/dto_convert_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: const Text("Dart Class from JSON Generator"),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DtoConvertScreen(),
                    ),
                  );
                },
                child: const Text("Convert Json to Api Dto and UIModel"),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CacheConvertScreen(),
                    ),
                  );
                },
                child: const Text("Convert Json to Cache Dto"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

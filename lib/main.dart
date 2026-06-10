import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/viewmodels/workout_viewmodel.dart';
import 'presentation/views/main_view.dart';

void main() {
  // Asegurar que el binding de Flutter esté inicializado antes de invocar la cámara o TTS
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NeoCoachApp());
}

class NeoCoachApp extends StatelessWidget {
  const NeoCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeoCoach',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFC3F400),
        scaffoldBackgroundColor: const Color(0xFF131313),
        // Configuramos el tema para que use estilos deportivos modernos oscuros
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC3F400),
          surface: Color(0xFF1C1C1E),
        ),
      ),
      home: ChangeNotifierProvider(
        create: (_) => WorkoutViewModel(),
        child: const MainView(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'models/habit.dart';
import 'screens/desafios_screen.dart';
import 'screens/habitos_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/app_bottom_nav.dart';

void main() {
  runApp(const EcoHabitsApp());
}

class EcoHabitsApp extends StatelessWidget {
  const EcoHabitsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eco Habits',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E8B3E)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentScreen = 0; // 0 = Desafios, 1 = Hábitos

  // Estado compartilhado entre as telas
  final List<Habit> _habits = [
    Habit(
        id: 1, name: 'Redução do tempo de banho', category: 'agua', done: true),
    Habit(id: 2, name: 'Economia de energia', category: 'energia'),
    Habit(id: 3, name: 'Reciclagem correta', category: 'reciclagem'),
    Habit(id: 4, name: 'Redução de lixo', category: 'lixo'),
    Habit(id: 5, name: 'Uso de transporte público', category: 'transporte'),
    Habit(id: 6, name: 'Alimentação sustentável', category: 'dieta'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Builder(
          builder: (_) {
            switch (_currentScreen) {
              case 0:
                return const Center(
                  child: Text('Home'),
                );

              case 1:
                return DesafiosScreen(
                  habits: _habits,
                  onNavigateToHabitos: () => setState(() => _currentScreen = 4),
                );

              case 2:
                return const Center(
                  child: Text('Adicionar'),
                );

              case 3:
                return const Center(
                  child: Text('Comunidade'),
                );

              case 4:
                return HabitosScreen(
                  habits: _habits,
                  onNavigateToDesafios: () =>
                      setState(() => _currentScreen = 1),
                );

              default:
                return const SizedBox();
            }
          },
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentScreen,
        onTap: (index) {
          setState(() {
            _currentScreen = index;
          });
        },
      ),
    );
  }
}

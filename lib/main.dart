import 'package:flutter/material.dart';

void main() {
  runApp(const EcoGuerreirosApp());
}

class EcoGuerreirosApp extends StatelessWidget {
  const EcoGuerreirosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Eco-Guerreiros',
      theme: ThemeData(
        brightness: Brightness.light,
      ),
      home: const EcoGuerreirosScreen(),
    );
  }
}

class EcoGuerreirosScreen extends StatefulWidget {
  const EcoGuerreirosScreen({super.key});

  @override
  State<EcoGuerreirosScreen> createState() => _EcoGuerreirosScreenState();
}

class _EcoGuerreirosScreenState extends State<EcoGuerreirosScreen> {
  bool isGlobalSelected = true;

  // Dados mockados para a aba GLOBAL
  final List<String> globalList = [
    "JOSE. A", "OLIVIA. S", "MARCOS. A", "******", "******",
    "******", "******", "******", "******", "******"
  ];

  // Dados mockados para a aba AMIGOS
  final List<String> amigosList = [
    "DANTAS", "JOSE", "Alves", "você", "******"
  ];

  @override
  Widget build(BuildContext context) {
    final currentList = isGlobalSelected ? globalList : amigosList;

    return Scaffold(
      backgroundColor: const Color(0xFF0A9B3E), // Cor de fundo verde
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Título
            const Text(
              "ECO-GUERREIROS",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 20),

            // Toggle Bar (Global / Amigos)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0xFF156530), // Fundo verde escuro do toggle
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isGlobalSelected = true),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isGlobalSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "GLOBAL",
                          style: TextStyle(
                            color: isGlobalSelected ? const Color(0xFF156530) : Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isGlobalSelected = false),
                      child: Container(
                        decoration: BoxDecoration(
                          color: !isGlobalSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "AMIGOS",
                          style: TextStyle(
                            color: !isGlobalSelected ? const Color(0xFF156530) : Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // Ação Adicionar/Remover Amigos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                children: [
                  Text(
                    isGlobalSelected ? "ADICIONAR AMIGOS" : "REMOVER AMIGOS",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    isGlobalSelected ? Icons.person_add_alt_1 : Icons.person_remove_alt_1,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 5),

            // Lista do Ranking (Cartão Branco)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: currentList.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      color: Colors.black26,
                      thickness: 1,
                    ),
                    itemBuilder: (context, index) {
                      return _buildListItem(index + 1, currentList[index]);
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Botão "Compartilhar seu impacto"
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 50),
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF156530),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 5,
                ),
                onPressed: () {},
                child: const Text(
                  "COMPARTILHAR SEU IMPACTO",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Bottom Navigation Bar flutuante
            Container(
              margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.home_outlined, color: Color(0xFF0A9B3E), size: 28),
                  Icon(Icons.rocket_launch_outlined, color: Color(0xFF0A9B3E), size: 28),
                  Icon(Icons.add_circle_outline, color: Color(0xFF0A9B3E), size: 30),
                  Icon(Icons.people_alt_outlined, color: Color(0xFF0A9B3E), size: 28),
                  Icon(Icons.person_outline, color: Color(0xFF0A9B3E), size: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(int rank, String name) {
    Color? rankColor;
    Color textColor = Colors.black;

    if (rank == 1) {
      rankColor = Colors.yellowAccent;
      textColor = Colors.black;
    } else if (rank == 2) {
      rankColor = Colors.grey;
      textColor = Colors.white;
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32);
      textColor = Colors.white;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: rankColor ?? Colors.transparent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              rank.toString(),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(width: 15),

          Container(
            width: 45,
            height: 45,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 15),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const Text(
                "PONTOS",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

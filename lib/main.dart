import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';

// --- PONTO DE ENTRADA ---
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameController()),
      ],
      child: const MestreDoRodizioApp(),
    ),
  );
}

// --- CONFIGURAÇÃO DO APP ---
class MestreDoRodizioApp extends StatelessWidget {
  const MestreDoRodizioApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos Consumer aqui para ouvir as mudanças de tema do Controller
    return Consumer<GameController>(
      builder: (context, controller, child) {
        return MaterialApp(
          title: 'Mestre do Rodízio',
          debugShowCheckedModeBanner: false,

          // --- TEMA CLARO ---
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.deepOrange,
            scaffoldBackgroundColor: Colors.grey[100],
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
            ),
            dialogTheme:  DialogThemeData(
              backgroundColor: Colors.white,
              elevation: 5,
            ),
            cardTheme: const CardThemeData(
              color: Colors.white,
            ),
          ),

          // --- TEMA ESCURO ---
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.deepOrange,
            scaffoldBackgroundColor: const Color(0xFF121212), // Fundo bem escuro
            useMaterial3: true,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.grey[900],
              foregroundColor: Colors.deepOrange,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: Colors.grey[850], // Fundo do dialog escuro
              elevation: 5,
            ),
            cardTheme: CardThemeData(
              color: Colors.grey[850], // Cards escuros
            ),
            // Ajuste para inputs ficarem visíveis no escuro
            inputDecorationTheme: const InputDecorationTheme(
              hintStyle: TextStyle(color: Colors.grey),
            ),
          ),

          // Define qual tema usar baseado na variável do controller
          themeMode: controller.isDarkMode ? ThemeMode.dark : ThemeMode.light,

          home: const HomeScreen(),
        );
      },
    );
  }
}

// --- MODELO (DADOS) ---
class Player {
  String id;
  String name;
  int score;

  Player({required this.id, required this.name, this.score = 0});
}

// --- CONTROLLER (LÓGICA) ---
class GameController extends ChangeNotifier {
  List<Player> players = [];
  int targetGoal = 10;
  String? winnerId;

  // Variável para controlar o tema
  bool isDarkMode = false;

  void toggleTheme(bool value) {
    isDarkMode = value;
    notifyListeners();
  }

  void addPlayer(String name) {
    if (name.isEmpty) return;
    players.add(Player(
      id: DateTime.now().toString(),
      name: name,
    ));
    notifyListeners();
  }

  void removePlayer(String playerId) {
    players.removeWhere((p) => p.id == playerId);

    // Se removermos o vencedor, o jogo deve continuar ou resetar o estado de vitória
    if (winnerId == playerId) {
      winnerId = null;
    }

    notifyListeners();
  }

  void incrementScore(String playerId) {
    if (winnerId != null) return;

    final index = players.indexWhere((p) => p.id == playerId);
    if (index != -1) {
      players[index].score++;

      if (players[index].score >= targetGoal) {
        winnerId = players[index].id;
      }

      players.sort((a, b) => b.score.compareTo(a.score));
      notifyListeners();
    }
  }

  void decrementScore(String playerId) {
    if (winnerId != null) return;

    final index = players.indexWhere((p) => p.id == playerId);
    if (index != -1 && players[index].score > 0) {
      players[index].score--;
      players.sort((a, b) => b.score.compareTo(a.score));
      notifyListeners();
    }
  }

  void setGoal(int newGoal) {
    if (newGoal > 0) {
      targetGoal = newGoal;
      final possibleWinner = players.where((p) => p.score >= targetGoal);
      if (possibleWinner.isNotEmpty) {
        winnerId = possibleWinner.first.id;
      } else {
        winnerId = null;
      }
      notifyListeners();
    }
  }

  void resetGame() {
    for (var p in players) {
      p.score = 0;
    }
    winnerId = null;
    notifyListeners();
  }

  String getWinnerName() {
    if (winnerId == null) return "";
    return players.firstWhere((p) => p.id == winnerId).name;
  }
}

// --- TELA PRINCIPAL (UI) ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showInputDialog(BuildContext context, String title, Function(String) onConfirm, {bool isNumber = false}) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.deepOrange)),
        content: TextField(
          controller: textController,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
              hintText: isNumber ? "Ex: 15" : "Ex: João",
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.deepOrange))
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
            onPressed: () {
              onConfirm(textController.text);
              Navigator.pop(ctx);
            },
            child: const Text("Confirmar"),
          ),
        ],
      ),
    );
  }

  String _getBadge(int score, int goal) {
    if (goal == 0) return "";
    double percentage = score / goal;
    if (percentage >= 1.0) return "👑 LENDÁRIO";
    if (percentage >= 0.75) return "🦖 Monstro";
    if (percentage >= 0.5) return "🦁 Faminto";
    if (percentage >= 0.25) return "😋 Aquecendo";
    return "👶 Iniciante";
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<GameController>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("🏆 Mestre do Rodízio"),
        centerTitle: true,
        elevation: 0,
        actions: [
          // SWITCH DE TEMA
          Row(
            children: [
              Icon(isDark ? Icons.dark_mode : Icons.light_mode, size: 18),
              Switch(
                value: controller.isDarkMode,
                activeThumbColor: Colors.white,
                activeTrackColor: Colors.orangeAccent,
                onChanged: (val) => controller.toggleTheme(val),
              ),
            ],
          ),
        ],
      ),
      // Stack para Animação de Vitória
      body: Stack(
        children: [
          // --- CAMADA 1: O App Normal ---
          Column(
            children: [
              // Painel da Meta
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                decoration: BoxDecoration(
                  // No dark mode usamos cinza escuro, no light usamos laranja
                    color: isDark ? Colors.grey[900] : Colors.deepOrange,
                    borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30)
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: isDark ? Colors.black45 : Colors.deepOrange.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5)
                      )
                    ]
                ),
                child: Column(
                  children: [
                    // Botão Reset (Movido para dentro do painel para limpar a AppBar)
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white70),
                        onPressed: () => controller.resetGame(),
                        tooltip: "Zerar placar",
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("META DA MESA", style: TextStyle(fontSize: 14, color: Colors.white70)),
                            Text(
                                "${controller.targetGoal}",
                                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white)
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(15)),
                          child: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: () {
                              _showInputDialog(context, "Nova Meta", (val) {
                                if (val.isNotEmpty) controller.setGoal(int.parse(val));
                              }, isNumber: true);
                            },
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),

              // Lista de Jogadores
              Expanded(
                child: controller.players.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu, size: 80, color: isDark ? Colors.grey[800] : Colors.orange.shade100),
                      const SizedBox(height: 20),
                      Text("Adicione os comilões!", style: TextStyle(color: Colors.grey.shade600, fontSize: 18)),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.only(top: 20, left: 15, right: 15, bottom: 80),
                  itemCount: controller.players.length,
                  itemBuilder: (context, index) {
                    final player = controller.players[index];
                    final progress = controller.targetGoal == 0 ? 0.0 : player.score / controller.targetGoal;
                    final isWinner = player.id == controller.winnerId;

                    Color progressColor = Colors.orange.shade300;
                    if (progress >= 0.5) progressColor = Colors.orange;
                    if (progress >= 0.8) progressColor = Colors.deepOrange;
                    if (isWinner) progressColor = Colors.green;

                    return Dismissible(
                      key: Key(player.id),
                      direction: DismissDirection.endToStart, // Arrastar da direita para esquerda
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.delete_forever, color: Colors.white, size: 32),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: isDark ? Colors.grey[900] : Colors.white,
                              title: const Text("Remover da mesa?", style: TextStyle(color: Colors.deepOrange)),
                              content: Text(
                                "${player.name} vai sair da disputa. Tem certeza?",
                                style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text("Remover", style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) {
                        controller.removePlayer(player.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("${player.name} saiu da mesa"))
                        );
                      },
                      child: Card(
                        elevation: isWinner ? 8 : 2,
                        shadowColor: isWinner ? Colors.green.withOpacity(0.4) : Colors.black12,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: isWinner ? const BorderSide(color: Colors.green, width: 3) : BorderSide.none
                        ),
                        margin: const EdgeInsets.only(bottom: 15),
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: isWinner ? Colors.green : (isDark ? Colors.orange.shade900 : Colors.orange.shade50),
                                child: Text(
                                  player.name.isNotEmpty ? player.name[0].toUpperCase() : "?",
                                  style: TextStyle(
                                      color: isWinner ? Colors.white : Colors.deepOrange,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 24
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                            player.name,
                                            style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 18,
                                                color: isDark ? Colors.white : Colors.black87
                                            )
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                              color: isWinner ? Colors.green.shade100 : (isDark ? Colors.grey[800] : Colors.orange.shade50),
                                              borderRadius: BorderRadius.circular(12)
                                          ),
                                          child: Text(
                                            _getBadge(player.score, controller.targetGoal),
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isWinner ? Colors.green.shade800 : Colors.deepOrange
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearProgressIndicator(
                                        value: progress > 1 ? 1 : progress,
                                        color: progressColor,
                                        backgroundColor: isDark ? Colors.grey[700] : Colors.grey.shade200,
                                        minHeight: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          "${player.score}",
                                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: progressColor),
                                        ),
                                        Text(
                                          " / ${controller.targetGoal}",
                                          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),

                              const SizedBox(width: 15),
                              Column(
                                children: [
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(50),
                                      onTap: controller.winnerId == null
                                          ? () => controller.incrementScore(player.id)
                                          : null,
                                      child: Ink(
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: controller.winnerId == null ? Colors.green : Colors.grey
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: const Icon(Icons.add, color: Colors.white, size: 28),
                                      ),
                                    ),
                                  ),
                                  if (player.score > 0 && controller.winnerId == null) ...[
                                    const SizedBox(height: 10),
                                    InkWell(
                                      onTap: () => controller.decrementScore(player.id),
                                      child: Icon(Icons.remove_circle_outline, size: 28, color: Colors.red.shade300),
                                    ),
                                  ]
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // --- CAMADA 2: Animação de Vitória ---
          if (controller.winnerId != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.85),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/trophy.json',
                      width: 300,
                      height: 300,
                      fit: BoxFit.contain,
                      repeat: false,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "TEMOS UM MESTRE!",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "${controller.getWinnerName()} destruiu a meta!",
                      style: TextStyle(color: Colors.orange.shade100, fontSize: 20),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            textStyle: const TextStyle(fontSize: 18)
                        ),
                        onPressed: () {
                          controller.resetGame();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text("Novo Rodízio")
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: controller.winnerId == null
          ? FloatingActionButton.extended(
        onPressed: () {
          _showInputDialog(context, "Nome do Comilão", (val) {
            controller.addPlayer(val);
          }, isNumber: false);
        },
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 10,
        label: const Text("Adicionar Pessoa", style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.person_add_alt_1),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
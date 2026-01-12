import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- PONTO DE ENTRADA ---
void main() {
  runApp(
    // Envolvemos o app no Provider para o estado fluir por toda a árvore
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
    return MaterialApp(
      title: 'Mestre do Rodízio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange, // Cor de comida!
        useMaterial3: true,
      ),
      home: const HomeScreen(),
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
  int targetGoal = 10; // Meta inicial
  String? winnerId;

  // Adicionar Jogador
  void addPlayer(String name) {
    if (name.isEmpty) return;
    players.add(Player(
      id: DateTime.now().toString(),
      name: name,
    ));
    notifyListeners();
  }

  // Incrementar Score
  void incrementScore(String playerId) {
    // Se já tiver vencedor, trava o jogo
    if (winnerId != null) return;

    final index = players.indexWhere((p) => p.id == playerId);
    if (index != -1) {
      players[index].score++;

      // Verifica Vitória
      if (players[index].score >= targetGoal) {
        winnerId = players[index].id;
      }

      // Ordena lista: quem tem mais pontos sobe
      players.sort((a, b) => b.score.compareTo(a.score));
      notifyListeners();
    }
  }

  // Decrementar Score (caso tenha clicado errado)
  void decrementScore(String playerId) {
    if (winnerId != null) return;

    final index = players.indexWhere((p) => p.id == playerId);
    if (index != -1 && players[index].score > 0) {
      players[index].score--;
      players.sort((a, b) => b.score.compareTo(a.score));
      notifyListeners();
    }
  }

  // Mudar Meta
  void setGoal(int newGoal) {
    if (newGoal > 0) {
      targetGoal = newGoal;
      // Verifica se alguém já ganhou com a nova meta (caso diminua a meta)
      final possibleWinner = players.where((p) => p.score >= targetGoal);
      if (possibleWinner.isNotEmpty) {
        winnerId = possibleWinner.first.id;
      } else {
        winnerId = null; // Reseta vencedor se a meta subir
      }
      notifyListeners();
    }
  }

  // Reiniciar tudo
  void resetGame() {
    for (var p in players) {
      p.score = 0;
    }
    winnerId = null;
    notifyListeners();
  }
}

// --- TELA PRINCIPAL (UI) ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Função auxiliar para mostrar dialog de input
  void _showInputDialog(BuildContext context, String title, Function(String) onConfirm, {bool isNumber = false}) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: textController,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(hintText: isNumber ? "Ex: 15" : "Ex: João"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
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

  // Função para dar "apelidos" baseados na pontuação
  String _getBadge(int score, int goal) {
    double percentage = score / goal;
    if (percentage >= 1.0) return "👑 LENDÁRIO";
    if (percentage >= 0.75) return "🦖 Monstro";
    if (percentage >= 0.5) return "🦁 Faminto";
    if (percentage >= 0.25) return "😋 Aquecendo";
    return "👶 Iniciante";
  }

  @override
  Widget build(BuildContext context) {
    // Acessando o estado
    final controller = Provider.of<GameController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("🏆 Mestre do Rodízio"),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Reiniciar Jogo?"),
                    content: const Text("Todos os contadores voltarão a zero."),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Não")),
                      TextButton(
                          onPressed: () {
                            controller.resetGame();
                            Navigator.pop(ctx);
                          },
                          child: const Text("Sim, reiniciar")
                      ),
                    ],
                  )
              );
            },
            tooltip: "Zerar placar",
          )
        ],
      ),
      body: Column(
        children: [
          // --- ÁREA DA META ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border(bottom: BorderSide(color: Colors.orange.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("META DO GRUPO", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                        "${controller.targetGoal} pedaços/copos",
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepOrange)
                    ),
                  ],
                ),
                IconButton(
                  style: IconButton.styleFrom(backgroundColor: Colors.white),
                  icon: const Icon(Icons.edit, color: Colors.deepOrange),
                  onPressed: () {
                    _showInputDialog(context, "Nova Meta", (val) {
                      if (val.isNotEmpty) controller.setGoal(int.parse(val));
                    }, isNumber: true);
                  },
                )
              ],
            ),
          ),

          // --- BANNER DE VENCEDOR ---
          if (controller.winnerId != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              padding: const EdgeInsets.all(15),
              color: Colors.green,
              width: double.infinity,
              child: Column(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.white, size: 40),
                  const SizedBox(height: 5),
                  Text(
                    "TEMOS UM VENCEDOR!",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    "Reinicie para jogar de novo.",
                    style: TextStyle(color: Colors.green.shade100, fontSize: 12),
                  )
                ],
              ),
            ),

          // --- LISTA DE JOGADORES ---
          Expanded(
            child: controller.players.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fastfood, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  const Text("Ninguém na mesa ainda..."),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: controller.players.length,
              itemBuilder: (context, index) {
                final player = controller.players[index];
                final progress = player.score / controller.targetGoal;
                final isWinner = player.id == controller.winnerId;

                // Define cor da barra baseada no progresso
                Color progressColor = Colors.blue;
                if (progress >= 0.5) progressColor = Colors.orange;
                if (progress >= 0.8) progressColor = Colors.red;
                if (isWinner) progressColor = Colors.green;

                return Card(
                  elevation: isWinner ? 8 : 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: isWinner ? const BorderSide(color: Colors.green, width: 2) : BorderSide.none
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: isWinner ? Colors.green : Colors.orange.shade100,
                          child: Text(
                            player.name.isNotEmpty ? player.name[0].toUpperCase() : "?",
                            style: TextStyle(
                                color: isWinner ? Colors.white : Colors.deepOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 20
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),

                        // Infos e Barra
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      player.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(10)
                                    ),
                                    child: Text(
                                      _getBadge(player.score, controller.targetGoal),
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 5),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: LinearProgressIndicator(
                                  value: progress > 1 ? 1 : progress,
                                  color: progressColor,
                                  backgroundColor: Colors.grey.shade200,
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "${player.score} / ${controller.targetGoal}",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              )
                            ],
                          ),
                        ),

                        // Botões de Ação (+ e -)
                        const SizedBox(width: 10),
                        Column(
                          children: [
                            InkWell(
                              onTap: controller.winnerId == null
                                  ? () => controller.incrementScore(player.id)
                                  : null,
                              child: Icon(Icons.add_circle, size: 36, color: controller.winnerId == null ? Colors.green : Colors.grey),
                            ),
                            if (player.score > 0)
                              InkWell(
                                onTap: controller.winnerId == null
                                    ? () => controller.decrementScore(player.id)
                                    : null,
                                child: Icon(Icons.remove_circle_outline, size: 24, color: Colors.red.shade300),
                              ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showInputDialog(context, "Nome do Participante", (val) {
            controller.addPlayer(val);
          }, isNumber: false);
        },
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        label: const Text("Adicionar Pessoa"),
        icon: const Icon(Icons.person_add),
      ),
    );
  }
}
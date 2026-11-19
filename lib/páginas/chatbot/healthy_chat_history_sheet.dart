import 'package:flutter/material.dart';
import '../../tema/healthy_theme.dart';
import 'healthy_chat_history.dart';

class HealthyChatHistorySheet extends StatelessWidget {
  const HealthyChatHistorySheet({
    super.key,
    required this.history,
    required this.activeId,
    required this.onSelected,
    required this.onNew,
  });

  final HealthyChatHistory history;
  final String? activeId;
  final ValueChanged<String> onSelected;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .65,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 10, 6),
            child: Row(children: [
              Expanded(child: Text('Conversaciones',
                style: TextStyle(color: HealthyAdaptive.text,
                  fontSize: 20, fontWeight: FontWeight.w900))),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onNew();
                },
                icon: const Icon(Icons.add_comment_outlined),
                label: const Text('Nueva'),
              ),
            ]),
          ),
          Expanded(
            child: StreamBuilder<List<HealthyChatSession>>(
              stream: history.watchSessions(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No se pudo cargar el historial. Comprueba tu conexión y los permisos de Firestore.',
                      textAlign: TextAlign.center)));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final sessions = snapshot.data!;
                if (sessions.isEmpty) {
                  return const Center(child: Text('No hay conversaciones anteriores.'));
                }
                return ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final chat = sessions[index];
                    return ListTile(
                      selected: chat.id == activeId,
                      leading: const Icon(Icons.chat_outlined),
                      title: Text(chat.title, maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                      subtitle: Text('${chat.updatedAt.day}/${chat.updatedAt.month}/${chat.updatedAt.year}'),
                      onTap: () {
                        Navigator.pop(context);
                        onSelected(chat.id);
                      },
                      trailing: IconButton(
                        tooltip: 'Eliminar chat',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Eliminar conversación'),
                              content: const Text('Se eliminarán todos los mensajes de esta conversación.'),
                              actions: [
                                TextButton(onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                                  child: const Text('Cancelar')),
                                FilledButton(onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                                  child: const Text('Eliminar')),
                              ],
                            ),
                          );
                          if (confirmed != true) return;
                          try {
                            await history.deleteSession(chat.id);
                            if (chat.id == activeId) onNew();
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text(
                                  'No se pudo eliminar esta conversación.')));
                            }
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

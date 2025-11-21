import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/ontology.dart';
import '../providers/semantic_providers.dart';
import 'ontology_editor_page.dart';

class OntologyListPage extends ConsumerWidget {
  const OntologyListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ontologiesAsync = ref.watch(ontologiesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ontologias'),
      ),
      body: ontologiesAsync.when(
        data: (ontologies) => _buildList(context, ref, ontologies),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add),
        tooltip: 'Nova Ontologia',
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, List<Ontology> ontologies) {
    if (ontologies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schema, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhuma ontologia criada',
              style: TextStyle(color: Colors.grey[600], fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text('Crie uma ontologia para definir classes e propriedades'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ontologies.length,
      itemBuilder: (context, index) {
        final ontology = ontologies[index];
        return _buildOntologyCard(context, ref, ontology);
      },
    );
  }

  Widget _buildOntologyCard(BuildContext context, WidgetRef ref, Ontology ontology) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OntologyEditorPage(ontologyId: ontology.id),
            ),
          ).then((_) => ref.refresh(ontologiesListProvider));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.schema, color: Colors.purple[700]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ontology.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (ontology.description != null)
                          Text(
                            ontology.description!,
                            style: TextStyle(color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Deletar'),
                          ],
                        ),
                        onTap: () async {
                          final controller = ref.read(ontologyControllerProvider.notifier);
                          await controller.delete(ontology.id);
                          ref.refresh(ontologiesListProvider);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.category,
                    '${ontology.classes.length} classes',
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    Icons.link,
                    '${ontology.properties.length} propriedades',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'v${ontology.version}',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Ontologia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                hintText: 'Ex: Aulas e Eventos',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                hintText: 'Descreva o propósito da ontologia',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              
              final controller = ref.read(ontologyControllerProvider.notifier);
              try {
                final ontology = await controller.create(
                  nameController.text.trim(),
                  descController.text.trim().isEmpty ? null : descController.text.trim(),
                );
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ref.refresh(ontologiesListProvider);
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OntologyEditorPage(ontologyId: ontology.id),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e')),
                  );
                }
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }
}

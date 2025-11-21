import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/semantic_template.dart';
import '../providers/semantic_providers.dart';
import 'ontology_list_page.dart';
import 'package:rdflib/rdflib.dart';

// Coloque esta função em um arquivo de utilitários (ex: 'uri_utils.dart') 
// ou na mesma classe/arquivo do seu widget. tentativa de corrigir um erro

String getXsdLabel(dynamic uri) {
  // Converte para String e trata casos nulos/vazios
  final uriString = uri?.toString();
  if (uriString == null || uriString.isEmpty) {
    return 'Tipo Desconhecido';
  }

  try {
    final parsedUri = Uri.parse(uriString);

    // 1. Prioriza o "fragment" (parte após o '#'), comum em XSD
    if (parsedUri.fragment.isNotEmpty) {
      return parsedUri.fragment;
    }

    // 2. Fallback: Usa o último segmento do path (parte após a última '/')
    if (parsedUri.pathSegments.isNotEmpty) {
      return parsedUri.pathSegments.last;
    }

    // 3. Retorna o host se não houver path/fragmento (exceção rara)
    return parsedUri.host;

  } catch (e) {
    // Retorna a string inteira ou um erro se o URI for inválido
    return uriString;
  }
}
////////////////////////////////////////////////////////////////////

class SemanticTemplatesPage extends ConsumerWidget {
  const SemanticTemplatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(allSemanticTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Templates Semânticos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.schema),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OntologyListPage()),
              ).then((_) => ref.refresh(allSemanticTemplatesProvider));
            },
            tooltip: 'Gerenciar Ontologias',
          ),
        ],
      ),
      body: templatesAsync.when(
        data: (templates) => _buildList(context, ref, templates),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, List<SemanticTemplate> templates) {
    if (templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhum template semântico',
              style: TextStyle(color: Colors.grey[600], fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text('Crie uma ontologia e gere templates a partir das classes'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OntologyListPage()),
                );
              },
              icon: const Icon(Icons.schema),
              label: const Text('Criar Ontologia'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _buildTemplateCard(context, ref, template);
      },
    );
  }

  Widget _buildTemplateCard(BuildContext context, WidgetRef ref, SemanticTemplate template) {
    final color = template.colorHex != null
        ? Color(int.parse(template.colorHex!.replaceFirst('#', '0xFF')))
        : Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showTemplateDetails(context, template),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconData(template.iconName),
                      color: color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (template.description != null)
                          Text(
                            template.description!,
                            style: TextStyle(color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          'Classe: ${template.mainClass.label}',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (!template.isActive)
                    Chip(
                      label: const Text('Inativo'),
                      backgroundColor: Colors.grey[300],
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
                          final controller = ref.read(semanticTemplateControllerProvider.notifier);
                          await controller.delete(template.id);
                          ref.refresh(allSemanticTemplatesProvider);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildInfoChip(
                    Icons.list,
                    '${template.properties.length} propriedades',
                  ),
                  _buildInfoChip(
                    Icons.star,
                    '${template.requiredProperties.length} obrigatórias',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'school':
        return Icons.school;
      case 'people':
        return Icons.people;
      case 'folder':
        return Icons.folder;
      case 'person':
        return Icons.person;
      case 'event':
        return Icons.event;
      case 'place':
        return Icons.place;
      case 'task':
        return Icons.task;
      default:
        return Icons.article;
    }
  }

  void _showTemplateDetails(BuildContext context, SemanticTemplate template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  template.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (template.description != null) ...[
                  const SizedBox(height: 8),
                  Text(template.description!, style: TextStyle(color: Colors.grey[600])),
                ],
                const SizedBox(height: 24),
                const Text('Classe Principal:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(template.mainClass.label),
                Text(template.mainClass.uri, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                const SizedBox(height: 24),
                const Text('Propriedades:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...template.properties.map((prop) => ListTile(
                  dense: true,
                  leading: Icon(
                    prop.isObjectProperty ? Icons.link : Icons.text_fields,
                    color: prop.isRequired ? Colors.red : Colors.grey,
                  ),
                  title: Row(
                    children: [
                      Text(prop.label),
                      if (prop.isRequired)
                        const Text(' *', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  subtitle: Text(
                    prop.isObjectProperty
                        ? 'Relacionamento'
                        : getXsdLabel(prop.rangeUri),
                  ),
                )),
                if (template.owlDefinition != null) ...[
                  const SizedBox(height: 24),
                  ExpansionTile(
                    title: const Text('Definição OWL'),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          template.owlDefinition!,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

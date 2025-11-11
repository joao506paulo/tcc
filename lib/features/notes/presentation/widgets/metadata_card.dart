import 'package:flutter/material.dart';
import '../../domain/entities/note.dart';

class MetadataCard extends StatelessWidget {
  final Note note;
  final VoidCallback? onRefresh;

  const MetadataCard({
    Key? key,
    required this.note,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Metadados',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onRefresh,
                    tooltip: 'Atualizar Metadados',
                  ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            
            // Título
            if (note.metadata['title'] != null)
              _buildMetadataItem(
                context,
                icon: Icons.title,
                label: 'Título',
                value: note.metadata['title'] as String,
              ),
            
            // Tags
            if (note.metadata['tags'] != null)
              _buildTagsSection(
                context,
                note.metadata['tags'] as List,
              ),
            
            // Links
            if (note.metadata['links'] != null)
              _buildLinksSection(
                context,
                note.metadata['links'] as List,
              ),
            
            // Contagem de palavras
            if (note.metadata['word_count'] != null)
              _buildMetadataItem(
                context,
                icon: Icons.text_fields,
                label: 'Palavras',
                value: note.metadata['word_count'].toString(),
              ),
            
            // Data de criação
            if (note.metadata['created_at'] != null)
              _buildMetadataItem(
                context,
                icon: Icons.calendar_today,
                label: 'Criado em',
                value: _formatDate(note.metadata['created_at'] as String),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(BuildContext context, List tags) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.label, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              const Text(
                'Tags:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) {
              return Chip(
                label: Text('#$tag'),
                backgroundColor: Colors.blue[100],
                labelStyle: const TextStyle(color: Colors.blue),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLinksSection(BuildContext context, List links) {
    if (links.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              const Text(
                'Links:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: links.map((link) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: InkWell(
                  onTap: () {
                    // Navegar para a nota linkada
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_right, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '[[${link}]]',
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    } catch (e) {
      return dateStr;
    }
  }
}

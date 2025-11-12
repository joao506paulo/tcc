import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/create_template.dart';
import '../providers/note_providers.dart';
import 'note_editor_page.dart';

class TemplatesPage extends ConsumerWidget {
  const TemplatesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(availableTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Templates'),
      ),
      body: templatesAsync.when(
        data: (templates) => _buildTemplatesList(context, ref, templates),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Erro ao carregar templates: $error'),
        ),
      ),
    );
  }

  Widget _buildTemplatesList(
    BuildContext context,
    WidgetRef ref,
    List<String> templates,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTemplateCard(
          context: context,
          ref: ref,
          templateType: 'daily-note',
          title: 'Nota Diária',
          description: 'Template para anotações do dia a dia',
          icon: Icons.today,
          color: Colors.blue,
        ),
        const SizedBox(height: 16),
        _buildTemplateCard(
          context: context,
          ref: ref,
          templateType: 'project',
          title: 'Projeto',
          description: 'Template para gerenciar projetos',
          icon: Icons.folder,
          color: Colors.orange,
        ),
        const SizedBox(height: 16),
        _buildTemplateCard(
          context: context,
          ref: ref,
          templateType: 'meeting',
          title: 'Reunião',
          description: 'Template para atas de reunião',
          icon: Icons.people,
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildTemplateCard({
    required BuildContext context,
    required WidgetRef ref,
    required String templateType,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showTemplateDialog(context, ref, templateType, title),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }

  void _showTemplateDialog(
    BuildContext context,
    WidgetRef ref,
    String templateType,
    String title,
  ) {
    final formKey = GlobalKey<FormState>();
    final variables = <String, String>{};

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Criar $title'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _buildTemplateFields(templateType, variables),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                Navigator.pop(context);
                await _createFromTemplate(
                  context,
                  ref,
                  templateType,
                  variables,
                );
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTemplateFields(
    String templateType,
    Map<String, String> variables,
  ) {
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    switch (templateType) {
      case 'daily-note':
        variables['date'] = today;
        variables['day_of_week'] = _getDayOfWeek(now.weekday);
        return [
          TextFormField(
            decoration: const InputDecoration(labelText: 'Data'),
            initialValue: today,
            onSaved: (value) => variables['date'] = value ?? today,
          ),
        ];

      case 'project':
        return [
          TextFormField(
            decoration: const InputDecoration(labelText: 'Nome do Projeto'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira o nome do projeto';
              }
              return null;
            },
            onSaved: (value) => variables['project_name'] = value ?? '',
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Data de Início'),
            initialValue: today,
            onSaved: (value) => variables['start_date'] = value ?? today,
          ),
        ];

      case 'meeting':
        return [
          TextFormField(
            decoration: const InputDecoration(labelText: 'Título da Reunião'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira o título';
              }
              return null;
            },
            onSaved: (value) => variables['meeting_title'] = value ?? '',
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Data'),
            initialValue: today,
            onSaved: (value) => variables['date'] = value ?? today,
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Participantes'),
            onSaved: (value) => variables['participants'] = value ?? '',
          ),
        ];

      default:
        return [];
    }
  }

  Future<void> _createFromTemplate(
    BuildContext context,
    WidgetRef ref,
    String templateType,
    Map<String, String> variables,
  ) async {
    try {
      final createTemplate = ref.read(createTemplateProvider);
      final storeData = ref.read(storeDataProvider);

      final note = await createTemplate(
        TemplateParams(
          templateType: templateType,
          variables: variables,
        ),
      );

      await storeData(note);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nota criada a partir do template!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NoteEditorPage(noteId: note.id),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar nota: $e')),
        );
      }
    }
  }

  String _getDayOfWeek(int weekday) {
    const days = [
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
      'Domingo',
    ];
    return days[weekday - 1];
  }
}

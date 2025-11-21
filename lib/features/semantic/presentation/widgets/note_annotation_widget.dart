import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/semantic_template.dart';
import '../../domain/entities/semantic_annotation.dart';
import '../../domain/entities/ontology_property.dart';
import '../providers/semantic_providers.dart';

class NoteAnnotationWidget extends ConsumerStatefulWidget {
  final String noteId;
  final VoidCallback? onAnnotationSaved;

  const NoteAnnotationWidget({
    super.key,
    required this.noteId,
    this.onAnnotationSaved,
  });

  @override
  ConsumerState<NoteAnnotationWidget> createState() => _NoteAnnotationWidgetState();
}

class _NoteAnnotationWidgetState extends ConsumerState<NoteAnnotationWidget> {
  SemanticTemplate? _selectedTemplate;
  final Map<String, dynamic> _propertyValues = {};
  final List<NoteRelation> _relations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingAnnotation();
  }

  Future<void> _loadExistingAnnotation() async {
    setState(() => _isLoading = true);
    
    final repository = ref.read(semanticRepositoryProvider);
    final annotation = await repository.getAnnotationByNoteId(widget.noteId);
    
    if (annotation != null) {
      final template = await repository.getTemplate(annotation.templateId);
      if (template != null) {
        setState(() {
          _selectedTemplate = template;
          _propertyValues.addAll(annotation.propertyValues);
          _relations.addAll(annotation.relations);
        });
      }
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(semanticTemplatesListProvider);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.label, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Anotação Semântica',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_selectedTemplate != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _clearAnnotation,
                    tooltip: 'Remover anotação',
                  ),
              ],
            ),
            const Divider(),
            
            // Seletor de template
            templatesAsync.when(
              data: (templates) {
                if (templates.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Nenhum template disponível.\nCrie ontologias e templates primeiro.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<SemanticTemplate>(
                      value: _selectedTemplate,
                      decoration: const InputDecoration(
                        labelText: 'Tipo da Nota',
                        hintText: 'Selecione um template',
                      ),
                      items: templates.map((t) => DropdownMenuItem(
                        value: t,
                        child: Row(
                          children: [
                            Icon(_getIconData(t.iconName), size: 20),
                            const SizedBox(width: 8),
                            Text(t.name),
                          ],
                        ),
                      )).toList(),
                      onChanged: (template) {
                        setState(() {
                          _selectedTemplate = template;
                          _propertyValues.clear();
                          _relations.clear();
                        });
                      },
                    ),
                    
                    if (_selectedTemplate != null) ...[
                      const SizedBox(height: 16),
                      _buildPropertyForm(),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveAnnotation,
                          icon: const Icon(Icons.save),
                          label: const Text('Salvar Anotação'),
                        ),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Erro: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyForm() {
    if (_selectedTemplate == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Propriedades:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._selectedTemplate!.properties.map((prop) => _buildPropertyField(prop)),
      ],
    );
  }

  Widget _buildPropertyField(OntologyProperty prop) {
    final currentValue = _propertyValues[prop.uri];

    if (prop.isObjectProperty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(prop.label),
                if (prop.isRequired)
                  const Text(' *', style: TextStyle(color: Colors.red)),
              ],
            ),
            const SizedBox(height: 4),
            TextField(
              decoration: InputDecoration(
                hintText: 'ID da nota relacionada',
                suffixIcon: const Icon(Icons.link),
                helperText: 'Relacionamento: ${prop.rangeUri.split('#').last}',
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  setState(() {
                    _relations.removeWhere((r) => r.propertyUri == prop.uri);
                    _relations.add(NoteRelation(
                      propertyUri: prop.uri,
                      targetNoteId: value,
                    ));
                  });
                }
              },
            ),
          ],
        ),
      );
    }

    // DataProperty
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _buildDataPropertyField(prop, currentValue),
    );
  }

  Widget _buildDataPropertyField(OntologyProperty prop, dynamic currentValue) {
    final rangeUri = prop.rangeUri;

    // Campo de data
    if (rangeUri == XsdDatatype.date || rangeUri == XsdDatatype.dateTime) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(prop.label),
              if (prop.isRequired)
                const Text(' *', style: TextStyle(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                setState(() {
                  _propertyValues[prop.uri] = date.toIso8601String().split('T')[0];
                });
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                suffixIcon: const Icon(Icons.calendar_today),
                hintText: 'Selecione uma data',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(currentValue?.toString() ?? 'Selecione...'),
            ),
          ),
        ],
      );
    }

    // Campo booleano
    if (rangeUri == XsdDatatype.boolean) {
      return SwitchListTile(
        title: Row(
          children: [
            Text(prop.label),
            if (prop.isRequired)
              const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        value: currentValue == true || currentValue == 'true',
        onChanged: (value) {
          setState(() {
            _propertyValues[prop.uri] = value;
          });
        },
      );
    }

    // Campo numérico
    if (rangeUri == XsdDatatype.integer || rangeUri == XsdDatatype.decimal) {
      return TextField(
        decoration: InputDecoration(
          labelText: '${prop.label}${prop.isRequired ? ' *' : ''}',
          hintText: rangeUri == XsdDatatype.integer ? 'Número inteiro' : 'Número decimal',
        ),
        keyboardType: TextInputType.number,
        controller: TextEditingController(text: currentValue?.toString()),
        onChanged: (value) {
          setState(() {
            if (rangeUri == XsdDatatype.integer) {
              _propertyValues[prop.uri] = int.tryParse(value);
            } else {
              _propertyValues[prop.uri] = double.tryParse(value);
            }
          });
        },
      );
    }

    // Campo de texto padrão
    return TextField(
      decoration: InputDecoration(
        labelText: '${prop.label}${prop.isRequired ? ' *' : ''}',
        hintText: XsdDatatype.getLabel(rangeUri),
      ),
      controller: TextEditingController(text: currentValue?.toString()),
      maxLines: prop.label.toLowerCase().contains('descri') ? 3 : 1,
      onChanged: (value) {
        setState(() {
          _propertyValues[prop.uri] = value;
        });
      },
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'school': return Icons.school;
      case 'people': return Icons.people;
      case 'folder': return Icons.folder;
      case 'person': return Icons.person;
      case 'event': return Icons.event;
      case 'place': return Icons.place;
      case 'task': return Icons.task;
      default: return Icons.article;
    }
  }

  Future<void> _saveAnnotation() async {
    if (_selectedTemplate == null) return;

    // Validar campos obrigatórios
    for (final prop in _selectedTemplate!.requiredProperties) {
      if (!_propertyValues.containsKey(prop.uri) || 
          _propertyValues[prop.uri] == null ||
          _propertyValues[prop.uri].toString().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Campo obrigatório: ${prop.label}')),
        );
        return;
      }
    }

    final controller = ref.read(annotationControllerProvider.notifier);
    try {
      await controller.annotate(
        noteId: widget.noteId,
        templateId: _selectedTemplate!.id,
        propertyValues: _propertyValues,
        relations: _relations,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anotação salva!')),
        );
        widget.onAnnotationSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  Future<void> _clearAnnotation() async {
    final controller = ref.read(annotationControllerProvider.notifier);
    await controller.delete(widget.noteId);
    
    setState(() {
      _selectedTemplate = null;
      _propertyValues.clear();
      _relations.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anotação removida')),
      );
    }
  }
}

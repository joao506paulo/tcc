import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/ontology.dart';
import '../../domain/entities/ontology_class.dart';
import '../../domain/entities/ontology_property.dart';
import '../providers/semantic_providers.dart';

class OntologyEditorPage extends ConsumerStatefulWidget {
  final String ontologyId;

  const OntologyEditorPage({super.key, required this.ontologyId});

  @override
  ConsumerState<OntologyEditorPage> createState() => _OntologyEditorPageState();
}

class _OntologyEditorPageState extends ConsumerState<OntologyEditorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOntology();
  }

  void _loadOntology() {
    ref.read(ontologyControllerProvider.notifier).load(widget.ontologyId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ontologyState = ref.watch(ontologyControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: ontologyState.when(
          data: (ont) => Text(ont?.name ?? 'Ontologia'),
          loading: () => const Text('Carregando...'),
          error: (_, __) => const Text('Erro'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.category), text: 'Classes'),
            Tab(icon: Icon(Icons.link), text: 'Propriedades'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportOwl(context),
            tooltip: 'Exportar OWL',
          ),
        ],
      ),
      body: ontologyState.when(
        data: (ontology) {
          if (ontology == null) {
            return const Center(child: Text('Ontologia não encontrada'));
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _buildClassesTab(context, ontology),
              _buildPropertiesTab(context, ontology),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddClassDialog(context);
          } else {
            _showAddPropertyDialog(context);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildClassesTab(BuildContext context, Ontology ontology) {
    if (ontology.classes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Nenhuma classe definida'),
            SizedBox(height: 8),
            Text('Adicione classes como Aula, Pessoa, Evento...'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ontology.classes.length,
      itemBuilder: (context, index) {
        final ontClass = ontology.classes[index];
        return _buildClassCard(context, ontology, ontClass);
      },
    );
  }

  Widget _buildClassCard(BuildContext context, Ontology ontology, OntologyClass ontClass) {
    final parentClass = ontClass.parentClassUri != null
        ? ontology.getClass(ontClass.parentClassUri!)
        : null;
    final properties = ontology.getPropertiesForClass(ontClass.uri);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.category, color: Colors.blue[700]),
        ),
        title: Text(ontClass.label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ontClass.description != null)
              Text(ontClass.description!, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (parentClass != null)
              Text('Herda de: ${parentClass.label}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('URI: ${ontClass.uri}', style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                const SizedBox(height: 8),
                if (properties.isNotEmpty) ...[
                  const Text('Propriedades:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ...properties.map((p) => Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Row(
                      children: [
                        Icon(
                          p.isObjectProperty ? Icons.link : Icons.text_fields,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(p.label),
                        if (p.isRequired)
                          const Text(' *', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  )),
                ],
                if (ontClass.restrictions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Restrições:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...ontClass.restrictions.map((r) => Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text('• $r', style: const TextStyle(fontSize: 12)),
                  )),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _createTemplateFromClass(context, ontClass),
                      icon: const Icon(Icons.article, size: 18),
                      label: const Text('Criar Template'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesTab(BuildContext context, Ontology ontology) {
    if (ontology.properties.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Nenhuma propriedade definida'),
            SizedBox(height: 8),
            Text('Adicione propriedades como temData, temProfessor...'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ontology.properties.length,
      itemBuilder: (context, index) {
        final prop = ontology.properties[index];
        return _buildPropertyCard(context, ontology, prop);
      },
    );
  }

  Widget _buildPropertyCard(BuildContext context, Ontology ontology, OntologyProperty prop) {
    final domainClass = ontology.getClass(prop.domainUri);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: prop.isObjectProperty ? Colors.green[100] : Colors.orange[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            prop.isObjectProperty ? Icons.link : Icons.text_fields,
            color: prop.isObjectProperty ? Colors.green[700] : Colors.orange[700],
          ),
        ),
        title: Row(
          children: [
            Text(prop.label, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (prop.isRequired)
              const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              prop.isObjectProperty ? 'ObjectProperty' : 'DataProperty',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            Text(
              'Domínio: ${domainClass?.label ?? prop.domainUri}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Range: ${_formatRangeUri(prop.rangeUri)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: prop.isFunctional
            ? const Chip(label: Text('Funcional', style: TextStyle(fontSize: 10)))
            : null,
      ),
    );
  }

  String _formatRangeUri(String uri) {
    if (uri.contains('XMLSchema')) {
      return XsdDatatype.getLabel(uri);
    }
    return uri.split('#').last;
  }

  void _showAddClassDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String? selectedParent;

    final ontologyState = ref.read(ontologyControllerProvider);
    final ontology = ontologyState.valueOrNull;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nova Classe'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Classe',
                    hintText: 'Ex: Aula, Pessoa, Evento',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição (opcional)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedParent,
                  decoration: const InputDecoration(
                    labelText: 'Classe Pai (opcional)',
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Nenhuma')),
                    ...?ontology?.classes.map((c) => DropdownMenuItem(
                      value: c.uri,
                      child: Text(c.label),
                    )),
                  ],
                  onChanged: (value) => setState(() => selectedParent = value),
                ),
              ],
            ),
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
                  await controller.addClass(
                    ontologyId: widget.ontologyId,
                    label: nameController.text.trim(),
                    description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                    parentClassUri: selectedParent,
                  );
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro: $e')),
                    );
                  }
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPropertyDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String? selectedDomain;
    String? selectedRange;
    PropertyType propertyType = PropertyType.dataProperty;
    bool isRequired = false;
    bool isFunctional = false;

    final ontologyState = ref.read(ontologyControllerProvider);
    final ontology = ontologyState.valueOrNull;

    if (ontology == null || ontology.classes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos uma classe primeiro')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nova Propriedade'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Propriedade',
                    hintText: 'Ex: tem Data, tem Professor',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
                ),
                const SizedBox(height: 16),
                const Text('Tipo:', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<PropertyType>(
                        title: const Text('Dado'),
                        subtitle: const Text('Texto, número, data...'),
                        value: PropertyType.dataProperty,
                        groupValue: propertyType,
                        onChanged: (v) => setState(() => propertyType = v!),
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<PropertyType>(
                        title: const Text('Objeto'),
                        subtitle: const Text('Outra classe'),
                        value: PropertyType.objectProperty,
                        groupValue: propertyType,
                        onChanged: (v) => setState(() => propertyType = v!),
                        dense: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedDomain,
                  decoration: const InputDecoration(labelText: 'Classe (Domínio) *'),
                  items: ontology.classes.map((c) => DropdownMenuItem(
                    value: c.uri,
                    child: Text(c.label),
                  )).toList(),
                  onChanged: (v) => setState(() => selectedDomain = v),
                ),
                const SizedBox(height: 16),
                if (propertyType == PropertyType.dataProperty)
                  DropdownButtonFormField<String>(
                    value: selectedRange ?? XsdDatatype.string,
                    decoration: const InputDecoration(labelText: 'Tipo de Dado *'),
                    items: XsdDatatype.all.map((uri) => DropdownMenuItem(
                      value: uri,
                      child: Text(XsdDatatype.getLabel(uri)),
                    )).toList(),
                    onChanged: (v) => setState(() => selectedRange = v),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: selectedRange,
                    decoration: const InputDecoration(labelText: 'Classe Alvo *'),
                    items: ontology.classes.map((c) => DropdownMenuItem(
                      value: c.uri,
                      child: Text(c.label),
                    )).toList(),
                    onChanged: (v) => setState(() => selectedRange = v),
                  ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Obrigatório'),
                  value: isRequired,
                  onChanged: (v) => setState(() => isRequired = v ?? false),
                  dense: true,
                ),
                CheckboxListTile(
                  title: const Text('Funcional (máximo 1 valor)'),
                  value: isFunctional,
                  onChanged: (v) => setState(() => isFunctional = v ?? false),
                  dense: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty || selectedDomain == null) {
                  return;
                }
                
                final rangeUri = selectedRange ?? 
                    (propertyType == PropertyType.dataProperty ? XsdDatatype.string : null);
                
                if (rangeUri == null) return;

                final controller = ref.read(ontologyControllerProvider.notifier);
                try {
                  await controller.addProperty(
                    ontologyId: widget.ontologyId,
                    label: nameController.text.trim(),
                    description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                    type: propertyType,
                    domainClassUri: selectedDomain!,
                    rangeUri: rangeUri,
                    isRequired: isRequired,
                    isFunctional: isFunctional,
                  );
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro: $e')),
                    );
                  }
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  void _createTemplateFromClass(BuildContext context, OntologyClass ontClass) async {
    final nameController = TextEditingController(text: ontClass.label);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Criar Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Criar template a partir da classe "${ontClass.label}"?'),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nome do Template'),
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
              final controller = ref.read(semanticTemplateControllerProvider.notifier);
              try {
                await controller.create(
                  ontologyId: widget.ontologyId,
                  classUri: ontClass.uri,
                  name: nameController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Template criado com sucesso!')),
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

  void _exportOwl(BuildContext context) async {
    final repository = ref.read(semanticRepositoryProvider);
    try {
      final owlXml = await repository.exportOntologyToOwl(widget.ontologyId);
      
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('OWL/XML'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: SingleChildScrollView(
                child: SelectableText(
                  owlXml,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
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
  }
}

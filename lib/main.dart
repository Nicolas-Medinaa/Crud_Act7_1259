import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:myapp/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Crud Nicolas Medina",
      debugShowCheckedModeBanner: false,
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final CollectionReference people =
      FirebaseFirestore.instance.collection('people');

  Future<void> _addPerson() async {
    final TextEditingController _nameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar nuevo nombre'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(hintText: 'Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              if (name.isNotEmpty) {
                await people.add({'name': name});
              }
              Navigator.pop(context);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(String name) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: Text('¿Estás seguro de eliminar "$name"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _editPerson(DocumentSnapshot doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPersonScreen(document: doc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crud Nicolas Medina"),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 236, 105, 105),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: people.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar los datos'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final name = doc['name'];
              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) => _confirmDelete(name),
                onDismissed: (direction) async {
                  await people.doc(doc.id).delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Eliminado "$name"')),
                  );
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: ListTile(
                  title: Text(
                    name,
                    style: const TextStyle(fontSize: 20),
                  ),
                  onTap: () => _editPerson(doc),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPerson,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class EditPersonScreen extends StatefulWidget {
  final DocumentSnapshot document;

  const EditPersonScreen({super.key, required this.document});

  @override
  State<EditPersonScreen> createState() => _EditPersonScreenState();
}

class _EditPersonScreenState extends State<EditPersonScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.document['name']);
  }

  Future<void> _updateName() async {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('people')
          .doc(widget.document.id)
          .update({'name': newName});
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar nombre'),
        backgroundColor: const Color.fromARGB(255, 236, 105, 105),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateName,
              child: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }
}
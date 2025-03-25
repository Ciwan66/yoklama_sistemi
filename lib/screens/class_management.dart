import 'package:flutter/material.dart';
import '../models/database_models.dart';
import '../screens/student_management.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  final TextEditingController _classNameController = TextEditingController();
  List<Class> classes = [];
  final _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() {
      _isLoading = true;
    });

    if (_authService.userId != null) {
      final loadedClasses =
          await _firestoreService.getAllClasses(_authService.userId!);
      setState(() {
        classes = loadedClasses;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addClass(String className) async {
    if (_authService.userId != null) {
      await _firestoreService.addClass(
        Class(
          name: className,
          userId: _authService.userId!,
        ),
      );
      _loadClasses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sınıf Yönetimi'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : classes.isEmpty
              ? _buildEmptyState()
              : _buildClassList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddClassDialog,
        icon: const Icon(Icons.add),
        label: const Text('Sınıf Ekle'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.class_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz Sınıf Yok',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlk sınıfınızı eklemek için aşağıdaki butona tıklayın',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddClassDialog,
            icon: const Icon(Icons.add),
            label: const Text('Sınıf Ekle'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      StudentManagementScreen(classId: classes[index].id!),
                ),
              ).then((_) => _loadClasses());
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.school,
                      size: 30,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classes[index].name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Öğrenci yönetimi için tıklayın',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _showDeleteConfirmation(classes[index]);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddClassDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Yeni Sınıf Ekle'),
          content: TextField(
            controller: _classNameController,
            decoration: const InputDecoration(
              labelText: 'Sınıf Adı',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.class_),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_classNameController.text.isNotEmpty) {
                  await _addClass(_classNameController.text);
                  _classNameController.clear();
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(Class classItem) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sınıfı Sil'),
          content: Text(
            '"${classItem.name}" sınıfını silmek istediğinizden emin misiniz? Bu işlem geri alınamaz ve tüm öğrenci verileri silinecektir.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _firestoreService.deleteClass(classItem.id!);
                Navigator.pop(context);
                _loadClasses();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _classNameController.dispose();
    super.dispose();
  }
}

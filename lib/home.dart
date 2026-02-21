import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final CollectionReference employees = FirebaseFirestore.instance.collection(
    'employees',
  );
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();

  String? docId;

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    super.dispose();
  }

  void openEmployeeDialog({DocumentSnapshot? doc}) {
    if (doc != null) {
      docId = doc.id;
      nameCtrl.text = doc['name'];
      emailCtrl.text = doc['email'];
    } else {
      docId = null;
      nameCtrl.clear();
      emailCtrl.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(docId == null ? 'Add Employee' : 'Edit Employee'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(hintText: 'Name'),
            ),

            TextField(
              controller: emailCtrl,
              decoration: InputDecoration(hintText: 'Email'),
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (doc == null) {
                    employees.add({
                      'name': nameCtrl.text,
                      'email': emailCtrl.text,
                      'createdAt':
                          FieldValue.serverTimestamp(), //Yes you can add more fields to your firestore like this, that's why tehreferene is doc.id not doc[index]
                    });
                  } else {
                    employees.doc(doc.id).update({
                      'name': nameCtrl.text,
                      'email': emailCtrl.text,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                  }
                  Navigator.pop(context);
                },
                child: Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: employees.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text("Error: ${snap.error}"));
          }

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(docs[index]['name'].toString()),
                subtitle: Text(docs[index]['email'].toString()),
                trailing: InkWell(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => openEmployeeDialog(doc: docs[index]),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          await employees.doc(docs[index].id).delete();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openEmployeeDialog(),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: Icon(Icons.add),
      ),
    );
  }
}

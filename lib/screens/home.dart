import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/notes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    titleController.dispose();
    descriptionController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var notesServices = context.watch<NotesServices>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter DAPP Notes'),
      ),
      body: notesServices.isLoading
          ? const Center(child: CupertinoActivityIndicator(),)
          : RefreshIndicator(
        onRefresh: () async {},
        child: ListView.builder(
          itemCount: notesServices.notes.length,
          itemBuilder: (context, index){
            return ListTile(
              title: Text(notesServices.notes[index].title),
              subtitle: Text(notesServices.notes[index].description),
              trailing: IconButton(
                  onPressed: () => notesServices.deleteNote(notesServices.notes[index].id),
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  )),
            );
          },
        ),),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
          onPressed: (){
          showDialog(
              context: context,
              builder: (context){
                return AlertDialog(
                  title: Text('New Note'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          hintText: 'Enter title',
                        ),
                      ),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          hintText: 'Enter description',
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        notesServices.addNote(
                          titleController.text,
                          descriptionController.text,
                        );
                        titleController.text = "";
                        descriptionController.text = "";
                        Navigator.pop(context);
                      },
                      child: const Text('Add'),
                    ),
                  ],
                );
              });
          }),
    );
  }
}

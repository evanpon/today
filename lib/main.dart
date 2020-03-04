import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Today',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List _items = List();
  int counter = 0;

  void _addItemToList(String item) {
    setState(() {
      Firestore.instance.collection('Items').document().setData(
        {'title': item, 'completed': false, 'notes': '', 'date': DateTime.now()}
      );
      _items.add(item);
    });
  }

  void _displayAddItemScreen() {
    Navigator.of(context).push(MaterialPageRoute<Null>(
        builder: (BuildContext context) {
          // return _addItemScreen();
          return new AddItemScreen();
        },
        fullscreenDialog: true));
  }

  String _getTodaysDate() {
    final now = new DateTime.now();
    final formatter = new DateFormat('MMMM dd');
    return formatter.format(now);
  }

  Widget _stackBehindDismissal() {
    return Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        color: Colors.red,
        child: Icon(Icons.delete, color: Colors.white));
  }

  Widget _createList(BuildContext context) {
    final collection = Firestore.instance.collection('Items');
    DateTime now = new DateTime.now();
    DateTime today = new DateTime(now.year, now.month, now.day);
    DateTime tomorrow = today.add(new Duration(days: 1));

    final query = collection
        .where("date", isGreaterThan: Timestamp.fromDate(today))
        .where("date", isLessThan: Timestamp.fromDate(tomorrow))
        .where("completed", isEqualTo: false);

    return StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return LinearProgressIndicator();
//       children: snapshot.map((data) => _buildListItem(context, data)).toList(),
          final documents = snapshot.data.documents;
          return ListView(
            // children: documents.map((documentSnapshot) => alpha()).toList(),
            children: documents.map((data) => _createCard(data)).toList(),
          );
        });
  }
  DateTime parseTime(dynamic date) {
    return Platform.isIOS ? (date as Timestamp).toDate() : (date as DateTime);
  }

  Widget _createCard(DocumentSnapshot data) {
    final x = data.data['date'];
    DateTime y = x.toDate();

    Item item = Item.fromSnapshot(data);
    Card card = Card(
      child: ListTile(title: Text(item.title)),
    );
    return Dismissible(
        key: ObjectKey(item),
        onDismissed: (direction) {
          item.complete();
        },
        background: _stackBehindDismissal(),
        child: card);
  }

  Widget _completedCount() {
    if (counter > 0) {
      return Row(
        children: <Widget>[
          Icon(Icons.check_circle),
          SizedBox(width: 5),
          Text(counter.toString()),
          SizedBox(width: 10)
        ],
      );
    } else {
      return SizedBox(width: 10);
    }
  }

// assignment_turned_in, check, check_box, check_circle, check_circle_outline,
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(_getTodaysDate()),
        actions: <Widget>[_completedCount()],
      ),
      body: _createList(context),
      floatingActionButton: FloatingActionButton(
        onPressed: _displayAddItemScreen,
        tooltip: 'Add Item',
        child: Icon(Icons.add),
        backgroundColor: Colors.deepOrange,
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class AddItemScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final _item = Item();

  void _submitForm() {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      Firestore.instance.collection('Items').document().setData(
        {'title': _item.title, 
         'completed': _item.completed, 
         'notes': _item.notes, 
         'date': _item.date}
      );
    }
    print("submitting form");
  }

  @override
  Widget build(BuildContext context) {
    FlatButton saveButton = FlatButton(
      child: Text(
        "SAVE",
        style: TextStyle(color: Colors.white),
      ),
      onPressed: () {
        _submitForm();
        Navigator.of(context).pop();
      },
    );
    TextFormField textField = TextFormField(
      decoration: InputDecoration(labelText: "Item"),
      validator: (String value) {
        if (value.isEmpty) {
          return "Item can't be blank";
        }
      },
      onSaved: (String value) {
        this._item.title = value;
      },
    );
    TextFormField textArea = TextFormField(
      decoration: InputDecoration(labelText: "Notes"),
      maxLines: null,
      onSaved: (String value) {
        this._item.notes = value;
      },
    );

    Column column = Column(
      children: <Widget>[textField, SizedBox(height: 20), textArea],
    );
    Form form = Form(child: column, key: _formKey);
    Padding padding = Padding(padding: EdgeInsets.all(8), child: form);
    return Scaffold(
        appBar: AppBar(
          title: Text('Add item'),
          actions: <Widget>[saveButton],
        ),
        body: padding);
  }
}
class Item {
  final Timestamp date;
  String title;
  String notes;
  bool completed;
  DocumentReference reference;

  Item() 
    : date = Timestamp.fromDate(DateTime.now()),
      completed = false;
  

  Item.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['title'] != null),
        assert(map['notes'] != null),
        assert(map['date'] != null),
        assert(map['completed'] != null),
        title = map['title'],
        notes = map['notes'],
        date = map['date'],
        completed = map['completed'];

  Item.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);

  void complete() {
    this.reference.updateData({'completed': true});
  }

  @override
  String toString() => "Record<$title:$notes>";
}

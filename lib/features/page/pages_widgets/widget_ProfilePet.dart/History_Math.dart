import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class HistoryMathPage extends StatefulWidget {
  final String userId;
  final String pet_type;

  const HistoryMathPage({
    Key? key,
    required this.userId,
    required this.pet_type,
  }) : super(key: key);

  @override
  _HistoryMathPageState createState() => _HistoryMathPageState();
}

class _HistoryMathPageState extends State<HistoryMathPage> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('ประวัติการจับคู่'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.report),
          ),
        ],
        toolbarHeight: 70.0,
      ),
      body: Container(
        child: Text("data"),
      ),
    );
  }
}

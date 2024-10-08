import 'package:flutter/material.dart';

class Message{
  final bool isUser;
  final String message;
  final DateTime date;

  Message({required this.isUser, required this.message, required this.date});
}

class Messages extends StatelessWidget {

  final bool isUser;
  final String message;
  final String date;

  const Messages(
      {
        super.key,
        required this.isUser,
        required this.message,
        required this.date
      });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.symmetric(vertical: 16).copyWith(
        left: 100,
        right: 10
      ),
      decoration: const BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(10),
          topRight: Radius.circular(10),
          topLeft: Radius.circular(10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(fontSize: 10,color: Colors.white),
          ),
          Text(
            date,
            style: const TextStyle(fontSize: 10,color: Colors.white),
          )
        ],
      ),
    );
  }
}
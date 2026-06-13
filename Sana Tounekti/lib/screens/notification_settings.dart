import 'package:flutter/material.dart';
import 'package:mymeds_app/components/language_constants.dart';

class NotificationSettings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translation(context).notificationSettings),
      ),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/4ewS.gif',
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            translation(context).notificationSubtitle,
            style: TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          )
        ],
      )),
    );
  }
}

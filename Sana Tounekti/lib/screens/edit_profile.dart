import 'package:flutter/material.dart';
import 'package:mymeds_app/components/language_constants.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translation(context).editProfile),
      ),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/user.webp',
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            translation(context).profileText1,
            style: TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            translation(context).profileText2,
            style: TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
        ],
      )),
    );
  }
}

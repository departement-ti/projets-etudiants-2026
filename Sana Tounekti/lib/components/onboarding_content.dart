import 'package:flutter/material.dart';
import 'package:mymeds_app/components/language_constants.dart';

class UnbordingContent {
  String image;
  String title;
  String description;

  UnbordingContent({
    required this.image,
    required this.title,
    required this.description,
  });
}

List<UnbordingContent> getContents(BuildContext context) {
  return [
    UnbordingContent(
        title: translation(context).onbTitle1,
        image: 'lib/assets/icons/1.gif',
        description: translation(context).onbDesc1),
    UnbordingContent(
        title: translation(context).onbTitle2,
        image: 'lib/assets/icons/2.gif',
        description: translation(context).onbDesc2),
    UnbordingContent(
        title: translation(context).onbTitle3,
        image: 'lib/assets/icons/3.gif',
        description: translation(context).onbDesc3),
    UnbordingContent(
        title: translation(context).onbTitle4,
        image: 'lib/assets/icons/4.gif',
        description: translation(context).onbDesc4),
  ];
}

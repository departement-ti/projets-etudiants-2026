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

List<UnbordingContent> contents = [
  UnbordingContent(
      title: 'Ne ratez plus jamais\nun médicament !',
      image: 'lib/assets/icons/1.gif',
      description:
          "Rappels intelligents pour chaque prise. Ne manquez plus aucune dose, même en déplacement."),
  UnbordingContent(
      title: 'Vos proches connectés\nen un clic',
      image: 'lib/assets/icons/2.gif',
      description:
          "Partagez votre planning avec votre famille et vos médecins. Restez entouré où que vous soyez."),
  UnbordingContent(
      title: 'Pharmacies et hôpitaux\nà proximité',
      image: 'lib/assets/icons/3.gif',
      description:
          "Trouvez facilement les services de santé les plus proches. Urgences, pharmacies, tout à portée de main."),
  UnbordingContent(
      title: 'Suivez votre santé\nau quotidien',
      image: 'lib/assets/icons/4.gif',
      description:
          "Statistiques, IMC, jeux cérébraux. Prenez le contrôle de votre bien-être en toute simplicité."),
];

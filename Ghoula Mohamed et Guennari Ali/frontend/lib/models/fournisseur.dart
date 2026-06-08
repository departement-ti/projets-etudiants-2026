class Fournisseur {
  final int? id;
  final String raisonSociale;
  final String? matriculeFiscal;
  final String? telephone;
  final String? email;
  final String? adresse;
  final String? ville;
  final String? pays;
  final String? categorieProduit;
  final String? modePaiement;
  final bool actif;

  Fournisseur({
    this.id,
    required this.raisonSociale,
    this.matriculeFiscal,
    this.telephone,
    this.email,
    this.adresse,
    this.ville,
    this.pays = 'Tunisie',
    this.categorieProduit,
    this.modePaiement,
    this.actif = true,
  });

  factory Fournisseur.fromJson(Map<String, dynamic> json) => Fournisseur(
        id: json['id'],
        raisonSociale: json['raisonSociale'] ?? '',
        matriculeFiscal: json['matriculeFiscal'],
        telephone: json['telephone'],
        email: json['email'],
        adresse: json['adresse'],
        ville: json['ville'],
        pays: json['pays'] ?? 'Tunisie',
        categorieProduit: json['categorieProduit'],
        modePaiement: json['modePaiement'],
        actif: json['actif'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'raisonSociale': raisonSociale,
        if (matriculeFiscal != null) 'matriculeFiscal': matriculeFiscal,
        if (telephone != null) 'telephone': telephone,
        if (email != null) 'email': email,
        if (adresse != null) 'adresse': adresse,
        if (ville != null) 'ville': ville,
        'pays': pays ?? 'Tunisie',
        if (categorieProduit != null) 'categorieProduit': categorieProduit,
        if (modePaiement != null) 'modePaiement': modePaiement,
        'actif': actif,
      };
}

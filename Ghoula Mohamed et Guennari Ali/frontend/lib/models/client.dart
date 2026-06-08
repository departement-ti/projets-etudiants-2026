class Client {
  final int? id;
  final String raisonSociale;
  final String? matriculeFiscal;
  final String? telephone;
  final String? email;
  final String? adresse;
  final String? ville;
  final String? typeClient;
  final double? plafondCredit;
  final int? delaiPaiement;
  final String? representantNom;
  final String? representantTelephone;
  final bool actif;

  Client({
    this.id,
    required this.raisonSociale,
    this.matriculeFiscal,
    this.telephone,
    this.email,
    this.adresse,
    this.ville,
    this.typeClient,
    this.plafondCredit,
    this.delaiPaiement,
    this.representantNom,
    this.representantTelephone,
    this.actif = true,
  });

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        id: json['id'],
        raisonSociale: json['raisonSociale'] ?? '',
        matriculeFiscal: json['matriculeFiscal'],
        telephone: json['telephone'],
        email: json['email'],
        adresse: json['adresse'],
        ville: json['ville'],
        typeClient: json['typeClient'],
        plafondCredit: (json['plafondCredit'] as num?)?.toDouble(),
        delaiPaiement: json['delaiPaiement'],
        representantNom: json['representantNom'],
        representantTelephone: json['representantTelephone'],
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
        if (typeClient != null) 'typeClient': typeClient,
        if (plafondCredit != null) 'plafondCredit': plafondCredit,
        if (delaiPaiement != null) 'delaiPaiement': delaiPaiement,
        if (representantNom != null) 'representantNom': representantNom,
        if (representantTelephone != null)
          'representantTelephone': representantTelephone,
        'actif': actif,
      };
}

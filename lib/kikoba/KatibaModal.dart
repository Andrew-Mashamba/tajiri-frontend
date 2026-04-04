

class Katiba {
  String kikobaid;
  String kiingilio;
  String ada;
  String hisa;
  String faini;
  String mikopo;
  String riba;

  String tenure;
  String fainiyamikopo;
  String reg_date;
  String kiingilioStatus;
  String adaStatus;
  String hisaStatus;
  String fainiVikao;
  String fainiVikaoStatus;
  String faini_adaStatus;
  String faini_ada;
  String faini_hisaStatus;
  String faini_hisa;
  String faini_michangoStatus;
  String faini_michango;

  Katiba(
      {
        required this.kikobaid,
        required this.kiingilio,
        required this.faini,
        required this.ada,
        required this.mikopo,
        required this.riba,
        required this.hisa,
        required this.tenure,
        required this.fainiyamikopo,
        required this.kiingilioStatus,
        required this.adaStatus,
        required this.hisaStatus,
        required this.fainiVikao,
        required this.fainiVikaoStatus,
        required this.faini_adaStatus,
        required this.faini_ada,
        required this.faini_hisaStatus,
        required this.faini_hisa,
        required this.faini_michangoStatus,
        required this.faini_michango,
        required this.reg_date
      });

  factory Katiba.fromJson(Map<String, dynamic> json) {
    return Katiba(
        kikobaid: json["kikobaid"],
        kiingilio: json["kiingilio"],
        faini: json["faini"],
        ada: json["ada"],
        mikopo: json["mikopo"],
        riba: json["riba"],
        hisa: json["hisa"],
        tenure: json["tenure"],
        fainiyamikopo: json["fainiyamikopo"],
        kiingilioStatus: json["kiingilioStatus"],
        adaStatus: json["adaStatus"],
        hisaStatus: json["hisaStatus"],
        fainiVikao: json["fainiVikao"],
        fainiVikaoStatus: json["fainiVikaoStatus"],
        faini_adaStatus: json["faini_adaStatus"],
        faini_ada: json["faini_ada"],
        faini_hisaStatus: json["faini_hisaStatus"],
        faini_hisa: json["faini_hisa"],
        faini_michangoStatus: json["faini_michangoStatus"],
        faini_michango: json["faini_michango"],
        reg_date: json["reg_date"]
    );
  }



}

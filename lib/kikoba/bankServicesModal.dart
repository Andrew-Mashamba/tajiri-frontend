

class bankServicesModal {

  String id = "";
  String Name = "";
  String MTI = "";
  String App_Category = "";

  bankServicesModal({required this.id, required this.Name, required this.MTI, required this.App_Category});

  bankServicesModal.fromMap(Map<String, dynamic> data) {
    id = data['id'].toString();
    Name = data['Name'].toString();
    MTI = data['MTI'].toString();
    App_Category = data['App_Category'].toString();
  }

  bankServicesModal.fromNetwork(Map<String, dynamic> data) : this.fromMap(data);

  toMap() => {
    'id': id,
    'Name': Name,
    'MTI': MTI,
    'App_Category': App_Category
  };


  factory bankServicesModal.fromJson(Map<dynamic, dynamic> json) {
    return bankServicesModal(
        id: json["id"].toString(),
        Name: json["Name"].toString(),
        MTI: json["MTI"].toString(),
        App_Category: json["App_Category"].toString()
    );
  }
}
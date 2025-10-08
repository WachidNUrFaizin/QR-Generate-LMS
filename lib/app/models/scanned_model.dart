class ScannedItem {
  final int? id;
  final String it;
  final String nt;
  final String at;
  final String pt;
  final String date;

  ScannedItem({
    this.id,
    required this.it,
    required this.nt,
    required this.at,
    required this.pt,
    required this.date
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'it': it,
      'nt': nt,
      'at': at,
      'pt': pt,
      'date': date
    };
  }

  factory ScannedItem.fromMap(Map<String, dynamic> map) {
    return ScannedItem(
        id: map['id'],
        it: map['it'],
        nt: map['nt'],
        at: map['at'],
        pt: map['pt'],
        date: map['date']
    );
  }



  @override
  String toString() {
    return 'ScannedItem{id: $id, it: $it, nt: $nt, at: $at,date: $date}';
  }

}
class CustomerItem {
  final int? id;
  final String it;
  final String nt;
  final String at;
  final String pt;
  final String ws;
  final String np;
  final String createdAt;

  CustomerItem({
    this.id,
    required this.it,
    required this.nt,
    required this.at,
    required this.pt,
    required this.ws,
    required this.np,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'it': it,
      'nt': nt,
      'at': at,
      'pt': pt,
      'ws': ws,
      'np': np,
      'created_at': createdAt,
    };
  }

  factory CustomerItem.fromMap(Map<String, dynamic> map) {
    return CustomerItem(
      id: map['id'] as int?,
      it: map['it'] ?? '',
      nt: map['nt'] ?? '',
      at: map['at'] ?? '',
      pt: map['pt'] ?? '',
      ws: map['ws'] ?? '',
      np: map['np'] ?? '',
      createdAt: map['created_at'] ?? '',
    );
  }

  CustomerItem copyWith({
    int? id,
    String? it,
    String? nt,
    String? at,
    String? pt,
    String? ws,
    String? np,
    String? createdAt,
  }) {
    return CustomerItem(
      id: id ?? this.id,
      it: it ?? this.it,
      nt: nt ?? this.nt,
      at: at ?? this.at,
      pt: pt ?? this.pt,
      ws: ws ?? this.ws,
      np: np ?? this.np,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
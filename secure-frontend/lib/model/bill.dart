class Bill {
  final int? id;
  final String payeeName;
  final DateTime dueDate;
  final double paymentDue;
  final bool paid;
  final int? version;

  Bill({
    this.id,
    required this.payeeName,
    required this.dueDate,
    required this.paymentDue,
    this.paid = false,
    this.version,
  });


///
///Writing to Json and reading from Json is a common task in Flutter when working with APIs. The `fromJson` factory constructor allows you to create a `Bill` instance from a JSON map, while the `toJson` method converts a `Bill` instance back into a JSON map.
///
 factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] as int?,
      payeeName: json['payeeName'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      paymentDue: json['paymentDue'] is String
          ? double.parse(json['paymentDue'] as String)
          : (json['paymentDue'] as num).toDouble(),
      paid: json['paid'] as bool? ?? false,
      version: json['version'] as int?,
    );
  }

  /// Writes the `Bill` instance to a JSON map. The `toJson` method is useful for sending data to APIs or saving it in a structured format. It includes all the necessary fields, and if the `id` or `version` is null, they will be omitted from the resulting JSON map.
  ///
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'payeeName': payeeName,
      // Assignment 6 expect yyyy-MM-dd, not the full ISO timestamp
      'dueDate': dueDate.toIso8601String().split('T').first,
      'paymentDue': paymentDue,
      'paid': paid,
      if (version != null) 'version': version,
    };
  }
}

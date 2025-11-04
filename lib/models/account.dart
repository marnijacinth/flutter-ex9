class Account {
  int? id;
  String accountHolder;
  double balance;

  Account({this.id, required this.accountHolder, required this.balance});

  factory Account.fromMap(Map<String, dynamic> map) => Account(
    id: map['id'] as int?,
    accountHolder: map['accountHolder'] as String,
    balance: (map['balance'] as num).toDouble(),
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'accountHolder': accountHolder,
    'balance': balance,
  };
}

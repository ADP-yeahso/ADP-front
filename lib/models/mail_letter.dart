class MailLetter {
  final int id;
  final String sender;
  final String receiver;
  final String content;
  final String date;
  final bool isAnonymous;
  bool isRead;

  MailLetter({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.content,
    required this.date,
    required this.isAnonymous,
    this.isRead = false,
  });
}

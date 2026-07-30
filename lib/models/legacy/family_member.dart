import 'package:flutter/material.dart';

class FamilyMember {
  final String id;
  final String nickname;
  final String relation;
  final Color color;
  final bool isMe;

  const FamilyMember({
    required this.id,
    required this.nickname,
    required this.relation,
    required this.color,
    this.isMe = false,
  });
}

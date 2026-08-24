import 'package:flutter/material.dart';
import 'package:huddle/core/resources/app_strings.dart';
import 'package:huddle/features/group/models/group_member_model.dart';
import 'package:huddle/features/shared/widgets/app_dropdown_field.dart';

/// Single-select picker over a group's members - used for the task assignee and the
/// expense payer, both of which need "who in this group" with a "(You)" hint for self.
class MemberDropdownField extends StatelessWidget {
  const MemberDropdownField({
    super.key,
    required this.hint,
    required this.members,
    required this.value,
    required this.currentUserId,
    required this.onChanged,
    this.enabled = true,
  });

  final String hint;
  final List<GroupMemberModel> members;
  final GroupMemberModel? value;
  final String? currentUserId;
  final ValueChanged<GroupMemberModel> onChanged;
  final bool enabled;

  String _labelFor(GroupMemberModel member) => member.userId == currentUserId ? '${member.name}${AppStrings.youSuffix}' : member.name;

  @override
  Widget build(BuildContext context) {
    return AppDropdownField<GroupMemberModel>(
      hint: hint,
      items: members,
      value: value,
      itemLabelBuilder: _labelFor,
      enabled: enabled,
      onChanged: onChanged,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vnu_core/modules/paht_v2/ktx/models/ktx_issue_models.dart';

class KtxIssueCard extends StatelessWidget {
  final KtxIssue issue;
  final KtxIssueMeta? meta;
  final VoidCallback onTap;

  const KtxIssueCard({
    super.key,
    required this.issue,
    required this.onTap,
    this.meta,
  });

  @override
  Widget build(BuildContext context) {
    final String createdAt = issue.createdAt == null
        ? 'Chưa có thời gian'
        : DateFormat('dd/MM/yyyy HH:mm').format(issue.createdAt!);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8E5)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F5EC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.apartment_rounded,
                      color: Color(0xFF078B3E),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      issue.title.isEmpty
                          ? 'Phản ánh #${issue.id}'
                          : issue.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF17201A),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(text: issue.displayStatus),
                ],
              ),
              if (issue.description.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  issue.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF657069),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _InfoChip(
                    icon: Icons.category_outlined,
                    text: issue.displayType(meta),
                  ),
                  if (issue.priority != null ||
                      issue.priorityLabel.isNotEmpty)
                    _InfoChip(
                      icon: Icons.flag_outlined,
                      text: issue.displayPriority(meta),
                    ),
                  if (issue.roomId != null)
                    _InfoChip(
                      icon: Icons.meeting_room_outlined,
                      text: 'Phòng #${issue.roomId}',
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: Color(0xFF8A948E),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      createdAt,
                      style: const TextStyle(
                        color: Color(0xFF8A948E),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF078B3E),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;

  const _StatusChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 118),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF078B3E),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E9E7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: const Color(0xFF66736B)),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF566159),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

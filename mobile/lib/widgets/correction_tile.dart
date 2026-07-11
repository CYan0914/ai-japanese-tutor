/// Correction tile — expandable grammar/vocab correction.
import 'package:flutter/material.dart';
import '../models/tutor_response.dart';

class CorrectionTile extends StatefulWidget {
  final Correction correction;

  const CorrectionTile({super.key, required this.correction});

  @override
  State<CorrectionTile> createState() => _CorrectionTileState();
}

class _CorrectionTileState extends State<CorrectionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                Text(
                    '${widget.correction.original}',
                    style: TextStyle(
                      color: Colors.red,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                    const SizedBox(width: 8),
                    Text(
                      '✅ ${widget.correction.corrected}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                    ),
                  ],
                ),
                if (_expanded && widget.correction.explanation.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      widget.correction.explanation,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

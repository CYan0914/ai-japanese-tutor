/// Correction tile — expandable grammar/vocab correction.
import 'package:flutter/material.dart';
import '../config/tokens.dart';
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
      padding: const EdgeInsets.only(left: 4, bottom: SakuraSpace.s, top: 2),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: const BorderRadius.all(SakuraRadius.s),
        child: Container(
          padding: const EdgeInsets.all(SakuraSpace.m),
          decoration: BoxDecoration(
            color: SakuraColors.white,
            borderRadius: const BorderRadius.all(SakuraRadius.s),
            border: Border.all(color: SakuraColors.bamboo),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.correction.original,
                    style: SakuraType.body(
                      color: SakuraColors.stone,
                      size: 14,
                    ).copyWith(decoration: TextDecoration.lineThrough),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.correction.corrected,
                    style: SakuraType.body(
                      color: SakuraColors.sumi,
                      size: 14,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 18,
                    color: SakuraColors.mist,
                  ),
                ],
              ),
              if (_expanded && widget.correction.explanation.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: SakuraSpace.s),
                  child: Text(
                    widget.correction.explanation,
                    style: SakuraType.body(color: SakuraColors.mist, size: 13),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

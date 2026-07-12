/// Models for the backend API responses.

class TutorResponse {
  final String yourMessage;
  final String japanesePhrase;
  final String romaji;
  final String pronunciationTips;
  final Evaluation? evaluation;
  final List<Correction> corrections;
  final String encouragement;

  TutorResponse({
    required this.yourMessage,
    required this.japanesePhrase,
    required this.romaji,
    required this.pronunciationTips,
    this.evaluation,
    required this.corrections,
    required this.encouragement,
  });

  factory TutorResponse.fromJson(Map<String, dynamic> json) {
    return TutorResponse(
      yourMessage: json['your_message'] as String? ?? '',
      japanesePhrase: json['japanese_phrase'] as String? ?? '',
      romaji: json['romaji'] as String? ?? '',
      pronunciationTips: json['pronunciation_tips'] as String? ?? '',
      evaluation: json['evaluation'] != null
          ? Evaluation.fromJson(json['evaluation'] as Map<String, dynamic>)
          : null,
      corrections: (json['corrections'] as List<dynamic>?)
              ?.map((e) => Correction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      encouragement: json['encouragement'] as String? ?? '',
    );
  }
}

class Evaluation {
  final bool accurate;
  final String whatWasGood;
  final String whatToImprove;
  final String practiceAgain;

  Evaluation({
    required this.accurate,
    required this.whatWasGood,
    required this.whatToImprove,
    required this.practiceAgain,
  });

  factory Evaluation.fromJson(Map<String, dynamic> json) {
    return Evaluation(
      accurate: json['accurate'] as bool? ?? false,
      whatWasGood: json['what_was_good'] as String? ?? '',
      whatToImprove: json['what_to_improve'] as String? ?? '',
      practiceAgain: json['practice_again'] as String? ?? '',
    );
  }
}

class Correction {
  final String original;
  final String corrected;
  final String explanation;

  Correction({
    required this.original,
    required this.corrected,
    required this.explanation,
  });

  factory Correction.fromJson(Map<String, dynamic> json) {
    return Correction(
      original: json['original'] as String? ?? '',
      corrected: json['corrected'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
    );
  }
}

class PronunciationScore {
  final int overall;
  final double acousticConfidence;
  final double? textAccuracy;
  final String level;
  final List<MoraScore>? details;
  final String feedback;

  PronunciationScore({
    required this.overall,
    required this.acousticConfidence,
    this.textAccuracy,
    required this.level,
    this.details,
    required this.feedback,
  });

  factory PronunciationScore.fromJson(Map<String, dynamic> json) {
    return PronunciationScore(
      overall: json['overall'] as int? ?? 0,
      acousticConfidence: (json['acoustic_confidence'] as num?)?.toDouble() ?? 0.0,
      textAccuracy: (json['text_accuracy'] as num?)?.toDouble(),
      level: json['level'] as String? ?? '',
      details: (json['details'] as List<dynamic>?)
          ?.map((e) => MoraScore.fromJson(e as Map<String, dynamic>))
          .toList(),
      feedback: json['feedback'] as String? ?? '',
    );
  }
}

class MoraScore {
  final String mora;
  final double confidence;

  MoraScore({required this.mora, required this.confidence});

  factory MoraScore.fromJson(Map<String, dynamic> json) {
    return MoraScore(
      mora: json['mora'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ChatResponse {
  final TutorResponse response;
  final String? audioUrl;
  final PronunciationScore? pronunciationScore;
  final UsageInfo usage;

  ChatResponse({
    required this.response,
    this.audioUrl,
    this.pronunciationScore,
    required this.usage,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      response: TutorResponse.fromJson(json['response'] as Map<String, dynamic>),
      audioUrl: json['audio_url'] as String?,
      pronunciationScore: json['pronunciation_score'] != null
          ? PronunciationScore.fromJson(json['pronunciation_score'] as Map<String, dynamic>)
          : null,
      usage: UsageInfo.fromJson(json['usage'] as Map<String, dynamic>),
    );
  }
}

class UsageInfo {
  final int lessonsUsedToday;
  final int lessonsRemaining;
  final String tier;

  UsageInfo({
    required this.lessonsUsedToday,
    required this.lessonsRemaining,
    required this.tier,
  });

  factory UsageInfo.fromJson(Map<String, dynamic> json) {
    return UsageInfo(
      lessonsUsedToday: json['lessons_used_today'] as int? ?? 0,
      lessonsRemaining: json['lessons_remaining'] as int? ?? 0,
      tier: json['tier'] as String? ?? 'free',
    );
  }

  bool get isPro => tier == 'pro';
}

// ── Phoneme Profile ──

class PhonemePoint {
  final String phoneme;
  final double avgScore;
  final int attempts;
  final String trend;
  final String lastPracticed;

  PhonemePoint({
    required this.phoneme,
    required this.avgScore,
    required this.attempts,
    required this.trend,
    required this.lastPracticed,
  });

  factory PhonemePoint.fromJson(Map<String, dynamic> json) {
    return PhonemePoint(
      phoneme: json['phoneme'] as String? ?? '',
      avgScore: (json['avg_score'] as num?)?.toDouble() ?? 0.0,
      attempts: json['attempts'] as int? ?? 0,
      trend: json['trend'] as String? ?? 'flat',
      lastPracticed: json['last_practiced'] as String? ?? '',
    );
  }

  /// 0-100 score → color
  String get level {
    if (avgScore >= 80) return 'good';
    if (avgScore >= 50) return 'ok';
    return 'weak';
  }
}

class PhonemeProfile {
  final String userId;
  final List<PhonemePoint> phonemes;
  final List<String> weakest;
  final String mostImproved;
  final String needsPractice;
  final int totalAttempts;
  final String lastUpdated;

  PhonemeProfile({
    required this.userId,
    required this.phonemes,
    required this.weakest,
    required this.mostImproved,
    required this.needsPractice,
    required this.totalAttempts,
    required this.lastUpdated,
  });

  factory PhonemeProfile.fromJson(Map<String, dynamic> json) {
    return PhonemeProfile(
      userId: json['user_id'] as String? ?? '',
      phonemes: (json['phonemes'] as List<dynamic>?)
              ?.map((e) => PhonemePoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      weakest: (json['weakest'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      mostImproved: json['most_improved'] as String? ?? '',
      needsPractice: json['needs_practice'] as String? ?? '',
      totalAttempts: json['total_attempts'] as int? ?? 0,
      lastUpdated: json['last_updated'] as String? ?? '',
    );
  }

  bool get isEmpty => phonemes.isEmpty;
}

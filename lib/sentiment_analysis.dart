// ════════════════════════════════════════════════════════════════════════════
//  customer_analysis.dart  —  Sentiment Analysis  (SaaS Dashboard Edition)
//  No backend required. All processing is local.
//
//  NLP Engine features:
//    • Phrase detection        (Phase 0 — before word loop)
//    • Context-window correction (±3 words, flips/softens polarity)
//    • Contrast detection      ("but rule" — post-contrast clause boosted)
//    • Negation window         (3-word window)
//    • Intensifier weighting
//    • 6-emotion detection
//    • Keyword extraction
//    • Zero-evidence neutral guard
// ════════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ════════════════════════════════════════════════════════════════════════════
//  DESIGN TOKENS
// ════════════════════════════════════════════════════════════════════════════
class _C {
  static const primary     = Color(0xFF2563EB);
  static const primarySoft = Color(0xFFEFF6FF);
  static const accent      = Color(0xFF0EA5E9);

  static const green      = Color(0xFF059669);
  static const greenSoft  = Color(0xFFECFDF5);
  static const greenMid   = Color(0xFF34D399);
  static const red        = Color(0xFFDC2626);
  static const redSoft    = Color(0xFFFEF2F2);
  static const redMid     = Color(0xFFF87171);
  static const amber      = Color(0xFFD97706);
  static const amberSoft  = Color(0xFFFFFBEB);
  static const amberMid   = Color(0xFFFBBF24);

  static const joy      = Color(0xFFF59E0B);
  static const anger    = Color(0xFFEF4444);
  static const sadness  = Color(0xFF3B82F6);
  static const fear     = Color(0xFFF97316);
  static const surprise = Color(0xFF8B5CF6);
  static const trust    = Color(0xFF10B981);

  static const lBg      = Color(0xFFF1F5F9);
  static const lSurface = Color(0xFFFFFFFF);
  static const lCard    = Color(0xFFFFFFFF);
  static const lBdr     = Color(0xFFE2E8F0);
  static const lBdrSub  = Color(0xFFF1F5F9);
  static const lT1      = Color(0xFF0F172A);
  static const lT2      = Color(0xFF475569);
  static const lT3      = Color(0xFF94A3B8);

  static const dBg      = Color(0xFF0B0F19);
  static const dSurface = Color(0xFF131929);
  static const dCard    = Color(0xFF1E2433);
  static const dCardAlt = Color(0xFF252D40);
  static const dBdr     = Color(0xFF2E3A52);
  static const dBdrSub  = Color(0xFF1E2433);
  static const dT1      = Color(0xFFF1F5F9);
  static const dT2      = Color(0xFF94A3B8);
  static const dT3      = Color(0xFF475569);
}

// ════════════════════════════════════════════════════════════════════════════
//  NLP ENGINE
// ════════════════════════════════════════════════════════════════════════════
enum _KType { positive, negative }

class _Keyword {
  final String word;
  final _KType type;
  final double weight;
  const _Keyword(this.word, this.type, this.weight);
}

class _SentimentResult {
  final String label;
  final double score;
  final double confidence;
  final double positive;
  final double negative;
  final double neutral;
  final Map<String, double> emotions;
  final List<_Keyword>      keywords;
  final int wordCount;
  final int sentenceCount;
  final int charCount;

  const _SentimentResult({
    required this.label,
    required this.score,
    required this.confidence,
    required this.positive,
    required this.negative,
    required this.neutral,
    required this.emotions,
    required this.keywords,
    required this.wordCount,
    required this.sentenceCount,
    required this.charCount,
  });

  bool get hasEvidence => confidence > 0.0;

  Color get color {
    if (label == 'Positive') return _C.green;
    if (label == 'Negative') return _C.red;
    return _C.amber;
  }

  Color get softColor {
    if (label == 'Positive') return _C.greenSoft;
    if (label == 'Negative') return _C.redSoft;
    return _C.amberSoft;
  }

  IconData get icon {
    if (label == 'Positive') return Icons.sentiment_very_satisfied_rounded;
    if (label == 'Negative') return Icons.sentiment_very_dissatisfied_rounded;
    return Icons.sentiment_neutral_rounded;
  }

  // Guard: no evidence → always Neutral regardless of default score (0.5)
  String get scoreLabel {
    if (!hasEvidence) return 'Neutral';
    if (score >= 0.80) return 'Very Positive';
    if (score >= 0.60) return 'Positive';
    if (score >= 0.45) return 'Slightly Positive';
    if (score >= 0.40) return 'Neutral';
    if (score >= 0.25) return 'Slightly Negative';
    if (score >= 0.10) return 'Negative';
    return 'Very Negative';
  }
}

class _SentimentEngine {

  // ── Positive lexicon ──────────────────────────────────────────────────────
  static const _pos = <String>{
    'great','excellent','amazing','wonderful','fantastic','love','loved',
    'good','best','perfect','awesome','happy','pleased','satisfied',
    'brilliant','outstanding','superb','delightful','incredible','positive',
    'enjoy','enjoyed','nice','helpful','smooth','easy','fast','beautiful',
    'recommend','recommended','thank','thanks','grateful','friendly','clean',
    'reliable','efficient','useful','convenient','affordable','worth',
    'responsive','quick','professional','impressive','exceptional','flawless',
    'seamless','intuitive','elegant','polished','innovative','thoughtful',
    'generous','transparent','honest','trustworthy','secure','powerful',
    'delighted','thrilled','overjoyed','ecstatic','content','comfortable',
    'refreshing','inspiring','motivating','rewarding','effective','accurate',
  };

  // ── Negative lexicon ──────────────────────────────────────────────────────
  static const _neg = <String>{
    'bad','terrible','awful','horrible','worst','hate','hated','poor',
    'disappointing','disappointed','slow','broken','useless','waste','wasted',
    'frustrating','frustrated','annoying','annoyed','difficult','expensive',
    'overpriced','unreliable','buggy','crash','crashed','error','fail',
    'failed','problem','issue','issues','ugly','confusing','confused',
    'unhelpful','rude','worse','defective','refund','return','regret',
    'avoid','scam','fake','misleading','deceptive','worthless','pathetic',
    'dreadful','disgusting','appalling','unacceptable','incompetent',
    'negligent','careless','sloppy','mediocre','substandard','inferior',
    'outdated','clunky','sluggish','unresponsive','unstable','insecure',
    'overcharged','delayed','missing','damaged','faulty',
  };

  // ── Negators (window = 3 words) ───────────────────────────────────────────
  static const _negators = <String>{
    'not','no','never','neither','nor','hardly','barely','scarcely',
    "don't","doesnt","didn't","isn't","wasn't","aren't","won't",
    "can't","cannot","couldn't","shouldn't","wouldn't","haven't","hasn't",
  };

  // ── Intensifiers ──────────────────────────────────────────────────────────
  static const _intensifiers = <String, double>{
    'very': 1.5, 'extremely': 2.0, 'absolutely': 2.0, 'totally': 1.5,
    'really': 1.3, 'quite': 1.2, 'so': 1.3, 'incredibly': 1.8,
    'super': 1.5, 'pretty': 1.1, 'somewhat': 0.7, 'slightly': 0.6,
    'utterly': 2.0, 'highly': 1.6, 'deeply': 1.5, 'truly': 1.4,
    'genuinely': 1.3, 'remarkably': 1.7, 'exceptionally': 1.9,
    'barely': 0.5, 'hardly': 0.5, 'almost': 0.8,
  };

  // ── Emotion lexicon ───────────────────────────────────────────────────────
  static const _emotions = <String, Set<String>>{
    'joy'     : {'happy','joy','love','loved','delightful','excited','wonderful',
                 'great','amazing','fantastic','excellent','thrilled','ecstatic',
                 'overjoyed','cheerful','elated','glad'},
    'anger'   : {'angry','furious','hate','frustrated','annoying','terrible',
                 'awful','horrible','rage','mad','outraged','infuriated','livid'},
    'sadness' : {'sad','disappointed','disappointing','unhappy','poor','regret',
                 'unfortunately','sorry','bad','worst','miserable','heartbroken',
                 'depressed','gloomy','sorrowful'},
    'fear'    : {'scared','worried','concern','concerning','fear','risky',
                 'dangerous','avoid','problem','anxious','nervous','frightened',
                 'alarmed','dread','apprehensive'},
    'surprise': {'wow','incredible','unbelievable','unexpected','sudden',
                 'shocked','amazing','impressive','outstanding','astonishing',
                 'astounding','staggering','remarkable'},
    'trust'   : {'reliable','trustworthy','honest','professional','helpful',
                 'efficient','secure','safe','recommend','dependable','consistent',
                 'transparent','accountable','credible'},
  };

  // ── Phrase lexicon (Phase 0 — scanned before word tokenisation) ───────────
  static const _phrases = <String, double>{
    'not bad': 1.0, 'not terrible': 0.8, 'not disappoint': 1.0,
    'not a problem': 0.8, 'very good': 2.0, 'very great': 2.0,
    'very helpful': 1.8, 'very reliable': 1.8, 'very easy': 1.6,
    'very fast': 1.6, 'really good': 1.8, 'really helpful': 1.8,
    'great service': 2.0, 'great quality': 2.0, 'great experience': 2.0,
    'great product': 1.8, 'high quality': 1.5, 'top quality': 1.5,
    'best quality': 2.0, 'good value': 1.5, 'good quality': 1.5,
    'good service': 1.5, 'worth the': 1.2, 'worth every': 1.5,
    'works perfectly': 2.0, 'works great': 1.8, 'works well': 1.5,
    'exceeded my': 2.0, 'exceeded expectations': 2.0,
    'highly recommend': 2.0, 'would recommend': 1.8,
    'easy to use': 1.5, 'easy to setup': 1.5, 'easy to install': 1.5,
    'fast delivery': 1.5, 'quick delivery': 1.5, 'on time': 1.2,
    'not good': -1.5, 'not great': -1.5, 'not worth': -2.0,
    'not worth it': -2.0, 'not recommend': -2.0, 'not helpful': -1.5,
    'not reliable': -1.5, 'not easy': -1.3, 'not happy': -1.5,
    'not satisfied': -1.5, 'not working': -1.8,
    'does not work': -2.0, 'did not work': -2.0,
    'very bad': -2.0, 'very slow': -1.8, 'very expensive': -1.8,
    'very difficult': -1.6, 'very poor': -2.0, 'very disappointing': -2.0,
    'really bad': -2.0, 'really slow': -1.8, 'really poor': -2.0,
    'too slow': -1.5, 'too expensive': -1.5, 'too difficult': -1.5,
    'too complicated': -1.5, 'too many issues': -1.8,
    'poor quality': -2.0, 'poor service': -2.0, 'poor experience': -2.0,
    'bad quality': -1.8, 'bad service': -1.8, 'bad experience': -1.8,
    'low quality': -1.5, 'waste of money': -2.0, 'waste of time': -2.0,
    'complete waste': -2.0, 'total waste': -2.0,
    'worst experience': -2.0, 'worst product': -2.0, 'worst service': -2.0,
    'would not recommend': -2.0, 'do not recommend': -2.0,
    'would not buy': -1.8, 'do not buy': -1.8,
    'stopped working': -1.8, 'broke after': -1.8, 'never again': -2.0,
    'complete disappointment': -2.0, 'utter disappointment': -2.0,
    'false advertising': -2.0, 'misleading description': -2.0,
  };

  // ── Context window: negative environment words ────────────────────────────
  // If a POSITIVE keyword sits within ±3 words of any of these, its polarity
  // is flipped to negative at half weight.
  // Example: "great jeopardy" → "great" flipped → net negative.
  static const _negContext = <String>{
    'jeopardy','danger','dangerous','risk','risky','threat','threatened',
    'problem','problems','failure','failures','fail','failed',
    'loss','losses','crisis','disaster','disasters','trouble','troubles',
    'concern','concerns','doubt','uncertainty','uncertainties',
    'fear','alarm','warning','warnings','damage','damages',
    'harm','harmful','injury','accident','accidents',
    'collapse','decline','deficit','obstacle','obstacles',
    'catastrophe','emergency','peril','hazard','hazards',
    'setback','setbacks','breakdown','deterioration','corruption',
  };

  // ── Context window: positive environment words ────────────────────────────
  // If a NEGATIVE keyword sits within ±3 words of any of these, its weight
  // is softened by 50%.
  // Example: "solve the problem" → "problem" softened → reduced penalty.
  static const _posContext = <String>{
    'solution','solutions','opportunity','opportunities',
    'improvement','improvements','success','achievement','achievements',
    'recovery','recovered','resolve','resolved','resolving','fix','fixed',
    'benefit','benefits','progress','advance','breakthrough','breakthroughs',
    'advantage','advantages','gain','gains','growth','potential',
    'strength','strengths','hope','hopeful','positive','overcome',
    'prevent','prevented','preventing','address','addressed',
    'mitigate','mitigated','manage','managed','control','controlled',
  };

  // ── Contrast conjunctions ("but rule") ───────────────────────────────────
  // The clause AFTER one of these carries higher sentiment weight (×1.6).
  // The clause BEFORE is slightly discounted (×0.7).
  // Example: "good product but terrible delivery" → delivery side dominates.
  static const _contrast = <String>{
    'but','however','although','though','yet','nevertheless',
    'nonetheless','still','despite','whereas','while','whilst',
    'even though','on the other hand','that said','having said that',
  };

  // ─────────────────────────────────────────────────────────────────────────
  static _SentimentResult analyze(String text) {
    if (text.trim().isEmpty) {
      return const _SentimentResult(
        label: 'Neutral', score: 0.5, confidence: 0.0,
        positive: 0.33, negative: 0.33, neutral: 0.34,
        emotions: {}, keywords: [], wordCount: 0,
        sentenceCount: 0, charCount: 0,
      );
    }

    final charCount     = text.trim().length;
    final sentenceCount = text
        .split(RegExp(r'[.!?]+'))
        .where((s) => s.trim().isNotEmpty)
        .length;

    // ── Phase 0: phrase-level scoring ────────────────────────────────────────
    // Scan the lowercased, whitespace-normalised text for every phrase entry.
    // Phrase scores seed posScore/negScore before word-level analysis runs.
    double phrasePos = 0.0;
    double phraseNeg = 0.0;
    final lowerText = text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    for (final entry in _phrases.entries) {
      int start = 0;
      while (true) {
        final idx = lowerText.indexOf(entry.key, start);
        if (idx == -1) break;
        final s = entry.value;
        if (s >= 0) {
          phrasePos += s;
        } else {
          phraseNeg -= s;
        }
        start = idx + entry.key.length;
      }
    }

    // ── Tokenise ─────────────────────────────────────────────────────────────
    final words = text.toLowerCase()
        .replaceAll(RegExp(r"[^\w\s']"), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    // ── Pass 1: context-window correction (±3 words) ─────────────────────────
    // For each word, inspect a ±3-word window.
    //   • Positive word near _negContext  → contextMult = -0.5 (flip to neg)
    //   • Negative word near _posContext  → contextMult =  0.5 (soften)
    //   • No surrounding context          → contextMult =  1.0 (unchanged)
    final contextMult = List<double>.filled(words.length, 1.0);

    for (var i = 0; i < words.length; i++) {
      final w      = words[i];
      final lo     = max(0,            i - 3);
      final hi     = min(words.length, i + 4); // exclusive
      final window = words.sublist(lo, hi);

      if (_pos.contains(w) && window.any(_negContext.contains)) {
        // Positive word surrounded by negative-context words → flip polarity
        contextMult[i] = -0.5;
      } else if (_neg.contains(w) && window.any(_posContext.contains)) {
        // Negative word surrounded by positive-context words → soften
        contextMult[i] = 0.5;
      }
    }

    // ── Pass 2: contrast detection ("but rule") ───────────────────────────────
    // Find the FIRST contrast conjunction. Words before it are discounted
    // (×0.7); words after it are boosted (×1.6).
    // This ensures "good product but terrible delivery" resolves as negative.
    final contrastWeight = List<double>.filled(words.length, 1.0);
    final contrastIdx    = words.indexWhere(_contrast.contains);

    if (contrastIdx >= 0) {
      for (var i = 0;               i < contrastIdx;    i++) {
        contrastWeight[i] = 0.7;
      }
      for (var i = contrastIdx + 1; i < words.length;  i++) {
        contrastWeight[i] = 1.6;
      }
    }

    // ── Word loop ─────────────────────────────────────────────────────────────
    // Seed accumulators with phrase scores so phrase + word levels both
    // contribute to the final polarity calculation.
    double posScore  = phrasePos;
    double negScore  = phraseNeg;
    int    negWindow = 0;
    bool   negated   = false;
    double intensity = 1.0;

    final foundKeywords = <_Keyword>[];

    for (var i = 0; i < words.length; i++) {
      final w = words[i];

      // Negation tracking
      if (negated) {
        negWindow++;
        if (negWindow > 3) { negated = false; negWindow = 0; }
      }

      if (_negators.contains(w)) { negated = true; negWindow = 0; continue; }
      if (_intensifiers.containsKey(w)) { intensity = _intensifiers[w]!; continue; }

      final isPos = _pos.contains(w);
      final isNeg = _neg.contains(w);

      if (isPos || isNeg) {
        // Combined weight = base intensity × |context correction| × contrast boost
        final mult   = contextMult[i];
        final weight = intensity * mult.abs() * contrastWeight[i];
        _KType ktype;

        // mult < 0 means context has flipped the word's effective polarity
        final effectivelyPos = (isPos && mult >= 0) || (isNeg && mult < 0);

        if (negated) {
          if (effectivelyPos) { negScore += weight; ktype = _KType.negative; }
          else                { posScore += weight * 0.5; ktype = _KType.positive; }
        } else {
          if (effectivelyPos) { posScore += weight; ktype = _KType.positive; }
          else                { negScore += weight; ktype = _KType.negative; }
        }

        foundKeywords.add(_Keyword(w, ktype, weight));
        negated = false; negWindow = 0; intensity = 1.0;
      } else {
        intensity = 1.0;
      }
    }

    // ── Score normalisation ───────────────────────────────────────────────────
    final rawTotal = posScore + negScore;
    final posRatio = rawTotal == 0 ? 0.5 : posScore / rawTotal;
    final negRatio = rawTotal == 0 ? 0.5 : negScore / rawTotal;
    final score    = (0.5 + (posRatio - negRatio) * 0.5).clamp(0.0, 1.0);

    // Distribution
    final base = (posRatio - negRatio).abs();
    final fPos = posRatio * (0.5 + base * 0.3);
    final fNeg = negRatio * (0.5 + base * 0.3);
    final fNeu = max(0.0, 1.0 - fPos - fNeg);
    final dSum = fPos + fNeg + fNeu;

    // Confidence
    final confidence = rawTotal == 0
        ? 0.0
        : (foundKeywords.length / max(words.length * 0.25, 1.0)).clamp(0.0, 1.0);

    // Zero-evidence neutral guard: if rawTotal == 0 the score (0.5) is
    // meaningless — force 'Neutral' unconditionally.
    String label;
    if (rawTotal == 0) {
      label = 'Neutral';
    } else if (score >= 0.58) label = 'Positive';
    else if (score <= 0.42) label = 'Negative';
    else                    label = 'Neutral';

    // ── Emotion scoring ───────────────────────────────────────────────────────
    final emotionScores = <String, double>{};
    for (final entry in _emotions.entries) {
      int count = 0;
      for (final w in words) { if (entry.value.contains(w)) count++; }
      if (count > 0) {
        emotionScores[entry.key] =
            (count / max(words.length * 0.15, 1.0)).clamp(0.0, 1.0);
      }
    }

    // ── Keyword deduplication ─────────────────────────────────────────────────
    final kwMap = <String, _Keyword>{};
    for (final k in foundKeywords) {
      if (!kwMap.containsKey(k.word) || k.weight > kwMap[k.word]!.weight) {
        kwMap[k.word] = k;
      }
    }
    final dedupedKw = kwMap.values.toList()
      ..sort((a, b) => b.weight.compareTo(a.weight));

    return _SentimentResult(
      label        : label,
      score        : score,
      confidence   : confidence,
      positive     : fPos / dSum,
      negative     : fNeg / dSum,
      neutral      : fNeu / dSum,
      emotions     : emotionScores,
      keywords     : dedupedKw.take(12).toList(),
      wordCount    : words.length,
      sentenceCount: sentenceCount,
      charCount    : charCount,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  HISTORY MODEL
// ════════════════════════════════════════════════════════════════════════════
class _HistoryEntry {
  final String   id, text, label;
  final double   score, confidence;
  final DateTime time;

  _HistoryEntry({
    required this.id, required this.text, required this.label,
    required this.score, required this.confidence, required this.time,
  });

  Color get color {
    if (label == 'Positive') return _C.green;
    if (label == 'Negative') return _C.red;
    return _C.amber;
  }
  Color get softColor {
    if (label == 'Positive') return _C.greenSoft;
    if (label == 'Negative') return _C.redSoft;
    return _C.amberSoft;
  }
  IconData get icon {
    if (label == 'Positive') return Icons.sentiment_very_satisfied_rounded;
    if (label == 'Negative') return Icons.sentiment_very_dissatisfied_rounded;
    return Icons.sentiment_neutral_rounded;
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'text': text, 'label': label,
    'score': score, 'confidence': confidence,
    'time': time.toIso8601String(),
  };
  static _HistoryEntry fromJson(Map<String, dynamic> j) => _HistoryEntry(
    id:         j['id']         as String,
    text:       j['text']       as String,
    label:      j['label']      as String,
    score:      (j['score']      as num).toDouble(),
    confidence: (j['confidence'] as num).toDouble(),
    time:       DateTime.parse(j['time'] as String),
  );
}

// ════════════════════════════════════════════════════════════════════════════
//  PAGE
// ════════════════════════════════════════════════════════════════════════════
class CustomerAnalysisPage extends StatefulWidget {
  const CustomerAnalysisPage({super.key});
  @override
  State<CustomerAnalysisPage> createState() => _CustomerAnalysisPageState();
}

class _CustomerAnalysisPageState extends State<CustomerAnalysisPage>
    with TickerProviderStateMixin {

  static const _maxChars   = 2000;
  static const _minChars   = 10;
  static const _maxHistory = 50;
  static const _storageKey = 'sentiment_history_v2';
  static const _themeKey   = 'dark_mode';

  bool              _dark      = false;
  int               _tabIndex  = 0;
  bool              _analyzing = false;
  _SentimentResult? _result;

  final _textCtrl  = TextEditingController();
  final _focusNode = FocusNode();
  String _inputText = '';
  List<_HistoryEntry> _history = [];

  late final AnimationController _revealCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();

    _revealCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim  = CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOutCubic));

    _pulseCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
        lowerBound: 0.85, upperBound: 1.0)
      ..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    _textCtrl.addListener(() {
      final v = _textCtrl.text;
      if (v != _inputText) setState(() => _inputText = v);
    });
    _loadPrefs();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _focusNode.dispose();
    _revealCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Theme helpers ─────────────────────────────────────────────────────────
  Color get bg      => _dark ? _C.dBg      : _C.lBg;
  Color get surface => _dark ? _C.dSurface : _C.lSurface;
  Color get card    => _dark ? _C.dCard    : _C.lCard;
  Color get cardAlt => _dark ? _C.dCardAlt : _C.lBdrSub;
  Color get bdr     => _dark ? _C.dBdr     : _C.lBdr;
  Color get t1      => _dark ? _C.dT1      : _C.lT1;
  Color get t2      => _dark ? _C.dT2      : _C.lT2;
  Color get t3      => _dark ? _C.dT3      : _C.lT3;

  TextStyle _h1(double sz) => GoogleFonts.dmSans(
      fontSize: sz, fontWeight: FontWeight.w700,
      color: t1, letterSpacing: -0.6, height: 1.2);

  TextStyle _h2(double sz) => GoogleFonts.dmSans(
      fontSize: sz, fontWeight: FontWeight.w600,
      color: t1, letterSpacing: -0.3);

  TextStyle _body(double sz, {
    Color? c,
    FontWeight fw = FontWeight.w400,
    double? ls,
    double? h,
  }) =>
      GoogleFonts.dmSans(
          fontSize: sz, fontWeight: fw,
          color: c ?? t2, letterSpacing: ls, height: h);

  TextStyle _mono(double sz, {Color? c}) =>
      GoogleFonts.jetBrainsMono(fontSize: sz, color: c ?? t1);

  // ════════════════════════════════════════════════════════════════════════
  //  PERSISTENCE
  // ════════════════════════════════════════════════════════════════════════
  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    final raw = p.getStringList(_storageKey) ?? [];
    final loaded = raw.map((s) {
      try { return _HistoryEntry.fromJson(jsonDecode(s) as Map<String, dynamic>); }
      catch (_) { return null; }
    }).whereType<_HistoryEntry>().toList();
    setState(() { _dark = p.getBool(_themeKey) ?? false; _history = loaded; });
  }

  Future<void> _persistHistory() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setStringList(
          _storageKey, _history.map((e) => jsonEncode(e.toJson())).toList());
    } catch (_) {}
  }

  Future<void> _saveTheme(bool v) async {
    try { await (await SharedPreferences.getInstance()).setBool(_themeKey, v); }
    catch (_) {}
  }

  // ════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: bg,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: LayoutBuilder(builder: (_, c) {
            final wide = c.maxWidth > 900;
            final hPad = wide ? 40.0 : 18.0;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPageHeader(),
                      const SizedBox(height: 24),
                      _buildTabBar(),
                      const SizedBox(height: 24),
                      _buildTabBody(wide),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() => AppBar(
    elevation: 0,
    scrolledUnderElevation: 0.5,
    backgroundColor: surface,
    surfaceTintColor: Colors.transparent,
    titleSpacing: 20,
    title: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_C.primary, _C.accent],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
      ),
      const SizedBox(width: 10),
      Text('SentimentAI', style: _h2(16)),
      const SizedBox(width: 8),
      _badge('v4.0', _C.primary),
    ]),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Divider(height: 1, color: bdr),
    ),
    actions: [
      if (_history.isNotEmpty)
        _iconBtn(Icons.delete_sweep_outlined, 'Clear history', _confirmClearHistory),
      _iconBtn(
        _dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        _dark ? 'Light mode' : 'Dark mode',
        () { setState(() => _dark = !_dark); _saveTheme(_dark); },
      ),
      const SizedBox(width: 8),
    ],
  );

  Widget _iconBtn(IconData icon, String tooltip, VoidCallback onTap) =>
      Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 18, color: t2),
          ),
        ),
      );

  // ── Page header ───────────────────────────────────────────────────────────
  Widget _buildPageHeader() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Text('ML Tools', style: _body(12, c: t3)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.chevron_right, size: 14, color: t3),
        ),
        Text('Sentiment Analysis',
            style: _body(12, c: _C.primary, fw: FontWeight.w600)),
      ]),
      const SizedBox(height: 10),
      Text('Sentiment Analysis', style: _h1(28)),
      const SizedBox(height: 6),
      Text(
        'Analyze text to detect sentiment, emotions, and key opinion signals.',
        style: _body(14, h: 1.55),
      ),
    ],
  );

  // ── Tab bar ───────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    final tabs = [
      (Icons.manage_search_rounded, 'Analyzer'),
      (Icons.history_rounded,       'History  (${_history.length})'),
      (Icons.bar_chart_rounded,     'Statistics'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bdr),
      ),
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final sel = _tabIndex == e.key;
          return Expanded(child: GestureDetector(
            onTap: () => setState(() => _tabIndex = e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: sel ? card : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                boxShadow: sel ? [BoxShadow(
                  color: Colors.black.withValues(alpha: _dark ? 0.3 : 0.06),
                  blurRadius: 8, offset: const Offset(0, 2),
                )] : null,
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(e.value.$1, size: 14, color: sel ? _C.primary : t3),
                const SizedBox(width: 6),
                Flexible(child: Text(e.value.$2,
                  overflow: TextOverflow.ellipsis,
                  style: _body(12,
                    c: sel ? _C.primary : t3,
                    fw: sel ? FontWeight.w600 : FontWeight.w400,
                  ),
                )),
              ]),
            ),
          ));
        }).toList(),
      ),
    );
  }

  Widget _buildTabBody(bool wide) {
    switch (_tabIndex) {
      case 0:  return _analyzerTab(wide);
      case 1:  return _historyTab();
      default: return _statsTab(wide);
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  //  TAB 0 — ANALYZER
  // ════════════════════════════════════════════════════════════════════════
  Widget _analyzerTab(bool wide) {
    final resultWidget = _result != null
        ? SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
                opacity: _fadeAnim, child: _resultDashboard(_result!)),
          )
        : _placeholderPanel();

    if (wide) {
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 420, child: _inputPanel()),
        const SizedBox(width: 20),
        Expanded(child: resultWidget),
      ]);
    }
    return Column(children: [
      _inputPanel(),
      const SizedBox(height: 20),
      resultWidget,
    ]);
  }

  // ── Input panel ───────────────────────────────────────────────────────────
  Widget _inputPanel() {
    final len       = _inputText.length;
    final overLimit = len > _maxChars;
    final tooShort  = len > 0 && len < _minChars;
    final canRun    = len >= _minChars && !overLimit && !_analyzing;

    return _card(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.edit_note_rounded, 'Input Text', _C.primary),
        const SizedBox(height: 16),

        Container(
          decoration: BoxDecoration(
            color: cardAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: overLimit ? _C.red
                   : _focusNode.hasFocus ? _C.primary : bdr,
              width: _focusNode.hasFocus || overLimit ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: _textCtrl,
            focusNode: _focusNode,
            maxLines: 9, minLines: 6,
            style: _body(14, c: t1, h: 1.65),
            textInputAction: TextInputAction.newline,
            onTap: () => setState(() {}),
            decoration: InputDecoration(
              hintText:
                  'Paste a customer review, tweet, or any text…\n\n'
                  'Example: "Absolutely amazing service — the team was '
                  'incredibly helpful and delivery exceeded expectations."',
              hintStyle: _body(13, h: 1.6),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(children: [
            if (tooShort)
              Text('Minimum $_minChars characters',
                  style: _body(11, c: _C.amber, fw: FontWeight.w500))
            else if (overLimit)
              Text('Exceeds $_maxChars character limit',
                  style: _body(11, c: _C.red, fw: FontWeight.w600))
            else if (_inputText.trim().isNotEmpty)
              Text('${_wordCount()} words', style: _body(11))
            else
              const SizedBox.shrink(),
            const Spacer(),
            Text('$len / $_maxChars',
                style: _body(11,
                  c: overLimit ? _C.red
                     : len > _maxChars * 0.85 ? _C.amber : t3,
                  fw: overLimit ? FontWeight.w600 : FontWeight.w400,
                )),
          ]),
        ),
        const SizedBox(height: 18),

        Text('Quick samples',
            style: _body(11, fw: FontWeight.w600, c: t3, ls: 0.4)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _sampleChip('😊 Positive', _C.green,
              'The product quality is absolutely amazing and delivery was super fast. '
              'Excellent customer service. I love everything about this. Highly recommended!'),
          _sampleChip('😞 Negative', _C.red,
              'Terrible experience. The product broke after one day and customer support '
              'was completely useless and rude. Worst purchase I have ever made. Avoid!'),
          _sampleChip('😐 Mixed', _C.amber,
              'The product is okay but delivery was quite slow. Some features are nice '
              'but others are frustrating and confusing. Not the best, not the worst.'),
          _sampleChip('🔁 Negation', _C.primary,
              'This is not good at all. I do not recommend this product. '
              'The quality is not reliable and the price is not worth it.'),
          _sampleChip('⚠️ Context', _C.fear,
              'That dream was now in great jeopardy. The plan faced serious risk '
              'of failure as the crisis deepened and losses continued to mount.'),
          _sampleChip('↔️ Contrast', _C.surprise,
              'The product design is elegant and beautiful but the performance '
              'is sluggish and the software crashes constantly. Very frustrating.'),
        ]),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: canRun ? _runAnalysis : null,
            style: FilledButton.styleFrom(
              backgroundColor: _C.primary,
              disabledBackgroundColor: _C.primary.withValues(alpha: 0.25),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: _analyzing
                ? ScaleTransition(
                    scale: _pulseAnim,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white)),
                        const SizedBox(width: 10),
                        Text('Analyzing…',
                            style: _body(14, c: Colors.white,
                                fw: FontWeight.w600)),
                      ]),
                  )
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.bolt_rounded,
                        size: 18, color: Colors.white),
                    const SizedBox(width: 6),
                    Text('Analyze Sentiment',
                        style: _body(14, c: Colors.white,
                            fw: FontWeight.w600)),
                  ]),
          ),
        ),
        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _inputText.isEmpty ? null : _clear,
            icon: Icon(Icons.close_rounded, size: 15,
                color: _inputText.isEmpty ? t3 : t2),
            label: Text('Clear',
                style: _body(14, c: _inputText.isEmpty ? t3 : t2)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: bdr),
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    ));
  }

  Widget _sampleChip(String label, Color color, String text) =>
      GestureDetector(
        onTap: () {
          _textCtrl.text = text;
          setState(() => _inputText = text);
          HapticFeedback.selectionClick();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Text(label, style: _body(12, c: color, fw: FontWeight.w500)),
        ),
      );

  // ── Placeholder ───────────────────────────────────────────────────────────
  Widget _placeholderPanel() => _card(
    child: SizedBox(
      height: 420,
      child: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                _C.primary.withValues(alpha: 0.12),
                _C.accent.withValues(alpha: 0.08),
              ], begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: _C.primary, size: 32),
          ),
          const SizedBox(height: 20),
          Text('No analysis yet', style: _h2(17)),
          const SizedBox(height: 8),
          Text('Enter text on the left and\ntap Analyze Sentiment',
              textAlign: TextAlign.center, style: _body(13, h: 1.6)),
          const SizedBox(height: 28),
          Wrap(
            spacing: 8, runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _featurePill(Icons.spellcheck_rounded,     'Lexicon NLP'),
              _featurePill(Icons.window_rounded,         'Context Window'),
              _featurePill(Icons.compare_arrows_rounded, 'Contrast Rule'),
              _featurePill(Icons.shield_outlined,        'On-device'),
              _featurePill(Icons.bolt_outlined,          'Instant'),
            ],
          ),
        ],
      )),
    ),
  );

  Widget _featurePill(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: _C.primary.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _C.primary.withValues(alpha: 0.18)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: _C.primary),
      const SizedBox(width: 5),
      Text(label, style: _body(11, c: _C.primary, fw: FontWeight.w500)),
    ]),
  );

  // ════════════════════════════════════════════════════════════════════════
  //  RESULT DASHBOARD
  // ════════════════════════════════════════════════════════════════════════
  Widget _resultDashboard(_SentimentResult r) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sentimentHeroRow(r),
      const SizedBox(height: 14),
      r.hasEvidence ? _polarityChartCard(r) : _noEvidenceCard(),
      const SizedBox(height: 14),
      if (r.emotions.isNotEmpty) ...[
        _emotionsCard(r.emotions),
        const SizedBox(height: 14),
      ],
      if (r.keywords.isNotEmpty) ...[
        _keywordsCard(r.keywords),
        const SizedBox(height: 14),
      ],
      _actionCard(r),
    ],
  );

  // ── Hero + mini stats ──────────────────────────────────────────────────────
  Widget _sentimentHeroRow(_SentimentResult r) => Column(children: [
    _card(
      borderColor: r.color.withValues(alpha: 0.3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: r.color.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(r.icon, color: r.color, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overall Sentiment',
                style: _body(11, fw: FontWeight.w600,
                    c: r.color.withValues(alpha: 0.8), ls: 0.5)),
            Text(r.scoreLabel, style: _h1(22).copyWith(color: r.color)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(children: [
                Container(
                  height: 7,
                  decoration: BoxDecoration(
                    color: r.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: r.score.clamp(0.0, 1.0),
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 7,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        r.color.withValues(alpha: 0.6), r.color,
                      ]),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 4),
            Row(children: [
              Text('Score', style: _body(10, c: t3)),
              const Spacer(),
              Text('${(r.score * 100).round()} / 100',
                  style: _mono(10, c: r.color)),
            ]),
          ],
        )),
        const SizedBox(width: 16),
        Tooltip(
          message: 'Copy result',
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _copyResult(r),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.copy_all_rounded, size: 16, color: t3),
            ),
          ),
        ),
      ]),
    ),
    const SizedBox(height: 10),
    Row(children: [
      _miniStat('Confidence', '${(r.confidence * 100).round()}%',
          Icons.verified_outlined, _C.primary),
      const SizedBox(width: 10),
      _miniStat('Words', '${r.wordCount}',
          Icons.text_fields_rounded, _C.accent),
      const SizedBox(width: 10),
      _miniStat('Sentences', '${r.sentenceCount}',
          Icons.short_text_rounded, _C.trust),
    ]),
  ]);

  Widget _miniStat(String label, String value, IconData icon, Color color) =>
      Expanded(child: _card(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: _h2(17).copyWith(letterSpacing: -0.5)),
              Text(label, style: _body(10, c: t3)),
            ],
          )),
        ]),
      ));

  // ── Polarity chart ────────────────────────────────────────────────────────
  Widget _polarityChartCard(_SentimentResult r) => _card(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeader(
          Icons.stacked_bar_chart_rounded, 'Polarity Distribution', _C.primary),
      const SizedBox(height: 18),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 24,
          child: Row(children: [
            _polaritySegment(r.positive, _C.green),
            _polaritySegment(r.neutral,  _C.amber),
            _polaritySegment(r.negative, _C.red),
          ]),
        ),
      ),
      const SizedBox(height: 14),
      _polarityRow('Positive', r.positive, _C.green,  _C.greenSoft),
      const SizedBox(height: 10),
      _polarityRow('Neutral',  r.neutral,  _C.amber,  _C.amberSoft),
      const SizedBox(height: 10),
      _polarityRow('Negative', r.negative, _C.red,    _C.redSoft),
    ],
  ));

  Widget _polaritySegment(double value, Color color) =>
      Expanded(
        flex: max(1, (value * 100).round()),
        child: Container(color: color),
      );

  Widget _polarityRow(
      String label, double value, Color color, Color soft) {
    final pct = (value * 100).round();
    return Row(children: [
      Container(width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      SizedBox(width: 64,
          child: Text(label,
              style: _body(13, fw: FontWeight.w500, c: t1))),
      const SizedBox(width: 8),
      Expanded(child: Stack(children: [
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          alignment: Alignment.centerLeft,
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.5), color]),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ])),
      const SizedBox(width: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: soft,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Text('$pct%', style: _mono(11, c: color)),
      ),
    ]);
  }

  // ── No-evidence card ──────────────────────────────────────────────────────
  Widget _noEvidenceCard() => _card(child: Row(children: [
    Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: _C.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.info_outline_rounded, color: _C.amber, size: 18),
    ),
    const SizedBox(width: 14),
    Expanded(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('No sentiment words detected',
            style: _h2(14).copyWith(color: _C.amber)),
        const SizedBox(height: 3),
        Text(
          'The text appears to be informational or neutral. '
          'No positive or negative opinion keywords were found.',
          style: _body(12, h: 1.55),
        ),
      ],
    )),
  ]));

  // ── Emotions card ──────────────────────────────────────────────────────────
  Widget _emotionsCard(Map<String, double> emotions) {
    final sorted = emotions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    const meta = <String, (IconData, Color)>{
      'joy'     : (Icons.emoji_emotions_rounded,         _C.joy),
      'anger'   : (Icons.local_fire_department_rounded,  _C.anger),
      'sadness' : (Icons.water_drop_outlined,            _C.sadness),
      'fear'    : (Icons.warning_amber_rounded,          _C.fear),
      'surprise': (Icons.auto_awesome_rounded,           _C.surprise),
      'trust'   : (Icons.verified_outlined,              _C.trust),
    };

    return _card(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
            Icons.emoji_emotions_outlined, 'Emotion Signals', _C.surprise),
        const SizedBox(height: 16),
        ...sorted.map((e) {
          final m     = meta[e.key] ?? (Icons.circle, t2);
          final color = m.$2;
          final pct   = (e.value * 100).round();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(m.$1, color: color, size: 15),
              ),
              const SizedBox(width: 10),
              SizedBox(width: 64,
                  child: Text(_cap(e.key),
                      style: _body(13, c: t1, fw: FontWeight.w500))),
              const SizedBox(width: 8),
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: e.value.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              )),
              const SizedBox(width: 10),
              SizedBox(width: 36,
                  child: Text('$pct%',
                      textAlign: TextAlign.right,
                      style: _mono(11, c: color))),
            ]),
          );
        }),
      ],
    ));
  }

  // ── Keywords card ──────────────────────────────────────────────────────────
  Widget _keywordsCard(List<_Keyword> keywords) => _card(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeader(Icons.sell_outlined, 'Opinion Keywords', _C.joy),
      const SizedBox(height: 14),
      Wrap(spacing: 8, runSpacing: 8,
          children: keywords.map(_keywordChip).toList()),
    ],
  ));

  Widget _keywordChip(_Keyword k) {
    final isPos = k.type == _KType.positive;
    final color = isPos ? _C.green : _C.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          isPos ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          size: 12, color: color,
        ),
        const SizedBox(width: 5),
        Text(k.word, style: _body(12, c: color, fw: FontWeight.w600)),
      ]),
    );
  }

  // ── Action card ───────────────────────────────────────────────────────────
  Widget _actionCard(_SentimentResult r) {
    final (title, body, icon, color) = switch (r.label) {
      'Positive' => (
          'Share & Amplify',
          'Positive feedback detected — use this as a testimonial, '
          'thank the customer personally, and replicate the experience '
          'that earned this sentiment.',
          Icons.campaign_outlined,
          _C.green,
        ),
      'Negative' => (
          'Escalate & Resolve',
          'Negative feedback detected — respond promptly, address the '
          'specific pain points highlighted, and escalate recurring issues '
          'to the product or support team.',
          Icons.support_agent_rounded,
          _C.red,
        ),
      _ => (
          'Follow Up',
          'Mixed or neutral sentiment — send a personalised follow-up or '
          'short survey to better understand the experience and convert '
          'neutral sentiment into loyalty.',
          Icons.contact_mail_outlined,
          _C.primary,
        ),
    };

    return _card(
      borderColor: color.withValues(alpha: 0.25),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader(Icons.tips_and_updates_rounded, 'Recommended Action', color),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _h2(13).copyWith(color: color)),
                const SizedBox(height: 4),
                Text(body, style: _body(13, h: 1.6)),
              ],
            )),
          ]),
        ),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  TAB 1 — HISTORY
  // ════════════════════════════════════════════════════════════════════════
  Widget _historyTab() {
    if (_history.isEmpty) {
      return _emptyState(Icons.history_rounded, _C.primary,
          'No history yet',
          'Analyze some text to start building\nyour sentiment history.');
    }

    final pos = _history.where((h) => h.label == 'Positive').length;
    final neg = _history.where((h) => h.label == 'Negative').length;
    final neu = _history.where((h) => h.label == 'Neutral').length;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Analysis History', style: _h2(18)),
            Text('${_history.length} of $_maxHistory entries stored',
                style: _body(12)),
          ],
        )),
        TextButton.icon(
          onPressed: _confirmClearHistory,
          icon: const Icon(Icons.delete_outline, size: 15, color: _C.red),
          label: Text('Clear all',
              style: _body(13, c: _C.red, fw: FontWeight.w500)),
        ),
      ]),
      const SizedBox(height: 16),
      Row(children: [
        _histSummaryCard('Positive', pos, _C.green,  _C.greenSoft),
        const SizedBox(width: 10),
        _histSummaryCard('Neutral',  neu, _C.amber,  _C.amberSoft),
        const SizedBox(width: 10),
        _histSummaryCard('Negative', neg, _C.red,    _C.redSoft),
      ]),
      const SizedBox(height: 20),
      ..._history.reversed.map((h) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _historyItemCard(h),
      )),
    ]);
  }

  Widget _histSummaryCard(
          String label, int count, Color color, Color soft) =>
      Expanded(child: _card(
        padding: const EdgeInsets.all(14),
        bgColor: soft,
        borderColor: color.withValues(alpha: 0.25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(count.toString(),
                style: _h1(26).copyWith(color: color)),
            Text(label,
                style: _body(11,
                    c: color.withValues(alpha: 0.75),
                    fw: FontWeight.w600)),
          ],
        ),
      ));

  Widget _historyItemCard(_HistoryEntry h) => _card(
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
            color: h.color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(h.icon, color: h.color, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            h.text.length > 140 ? '${h.text.substring(0, 140)}…' : h.text,
            style: _body(13, c: t1, h: 1.5),
          ),
          const SizedBox(height: 7),
          Row(children: [
            _badge(h.label, h.color),
            const SizedBox(width: 6),
            _badge('${(h.confidence * 100).round()}% conf', h.color),
            const Spacer(),
            Text(_formatTime(h.time), style: _body(11)),
          ]),
        ],
      )),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: () {
          setState(() => _history.remove(h));
          _persistHistory();
        },
        child: Padding(
          padding: const EdgeInsets.only(left: 4, top: 2),
          child: Icon(Icons.close_rounded, size: 14, color: t3),
        ),
      ),
    ]),
  );

  // ════════════════════════════════════════════════════════════════════════
  //  TAB 2 — STATISTICS
  // ════════════════════════════════════════════════════════════════════════
  Widget _statsTab(bool wide) {
    if (_history.isEmpty) {
      return _emptyState(Icons.bar_chart_rounded, _C.primary,
          'No data yet', 'Analyze some text to see\nstatistics here.');
    }

    final total    = _history.length;
    final pos      = _history.where((h) => h.label == 'Positive').length;
    final neg      = _history.where((h) => h.label == 'Negative').length;
    final neu      = total - pos - neg;
    final avgScore = _history.fold(0.0, (a, h) => a + h.score) / total;
    final avgConf  = _history.fold(0.0, (a, h) => a + h.confidence) / total;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Statistics', style: _h2(18)),
      Text('Based on $total text${total == 1 ? '' : 's'} analyzed',
          style: _body(12)),
      const SizedBox(height: 20),

      LayoutBuilder(builder: (_, c) {
        final cols  = c.maxWidth > 540 ? 4 : 2;
        final items = [
          ('Total',     total.toString(),                   Icons.analytics_outlined,  _C.primary),
          ('Avg Score', '${(avgScore * 100).round()}%',     Icons.show_chart_rounded,  _C.accent),
          ('Avg Conf.', '${(avgConf  * 100).round()}%',     Icons.verified_outlined,   _C.trust),
          ('Pos. Rate', '${(pos * 100 / total).round()}%',  Icons.thumb_up_outlined,   _C.green),
        ];
        return Wrap(spacing: 10, runSpacing: 10,
          children: items.map((s) => SizedBox(
            width: (c.maxWidth - (cols - 1) * 10) / cols,
            child: _statCard(s.$1, s.$2, s.$3, s.$4),
          )).toList(),
        );
      }),
      const SizedBox(height: 20),

      _card(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.donut_large_rounded,
              'Sentiment Distribution', _C.primary),
          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(height: 22, child: Row(children: [
              if (pos > 0) Expanded(flex: pos, child: Container(color: _C.green)),
              if (neu > 0) Expanded(flex: neu, child: Container(color: _C.amber)),
              if (neg > 0) Expanded(flex: neg, child: Container(color: _C.red)),
            ])),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 18, runSpacing: 6, children: [
            _legendDot('Positive', pos, total, _C.green),
            _legendDot('Neutral',  neu, total, _C.amber),
            _legendDot('Negative', neg, total, _C.red),
          ]),
          const SizedBox(height: 22),

          Text('Recent Scores', style: _h2(13)),
          const SizedBox(height: 12),
          ..._history.reversed.take(10).toList().asMap().entries.map((e) {
            final h   = e.value;
            final idx = e.key + 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                SizedBox(width: 24,
                    child: Text('#$idx', style: _body(11, c: t3))),
                const SizedBox(width: 8),
                Expanded(child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: h.score,
                    minHeight: 9,
                    backgroundColor: h.color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(h.color),
                  ),
                )),
                const SizedBox(width: 10),
                SizedBox(width: 68, child: _badge(h.label, h.color)),
              ]),
            );
          }),
        ],
      )),
      const SizedBox(height: 20),

      _card(
        bgColor: _dark ? _C.dCardAlt : _C.primarySoft,
        borderColor: _C.primary.withValues(alpha: 0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
                Icons.info_outline_rounded, 'About the Engine', _C.primary),
            const SizedBox(height: 14),
            _engineFact(Icons.spellcheck_rounded,           _C.primary,
                'Lexicon-Based NLP',
                '120+ curated sentiment entries'),
            _engineFact(Icons.chat_bubble_outline_rounded,  _C.green,
                'Phrase Detection (Phase 0)',
                '50+ multi-word phrases scanned before tokenisation'),
            _engineFact(Icons.window_rounded,               _C.accent,
                'Context Window (±3 words)',
                '"great jeopardy" → great flipped to negative'),
            _engineFact(Icons.compare_arrows_rounded,       _C.surprise,
                'Contrast Detection ("but rule")',
                'Post-contrast clause boosted ×1.6; pre-contrast ×0.7'),
            _engineFact(Icons.undo_rounded,                 _C.sadness,
                'Negation Window (3-word)',
                '"not good", "don\'t recommend", "wasn\'t helpful"'),
            _engineFact(Icons.speed_rounded,                _C.fear,
                'Intensifier Weighting',
                '"extremely", "slightly", "barely" adjustments'),
            _engineFact(Icons.check_circle_outline_rounded, _C.amber,
                'Zero-Evidence Neutral Guard',
                'Forces Neutral when confidence = 0%'),
            _engineFact(Icons.psychology_outlined,          _C.joy,
                '6-Emotion Detection',
                'Joy · Anger · Sadness · Fear · Surprise · Trust'),
            _engineFact(Icons.offline_bolt_rounded,         _C.trust,
                '100% On-Device',
                'No internet, instant, fully private'),
          ],
        ),
      ),
    ]);
  }

  Widget _statCard(String label, String value, IconData icon, Color color) =>
      _card(padding: const EdgeInsets.all(14), child:
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              Container(width: 6, height: 6,
                  decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle)),
            ]),
            const SizedBox(height: 10),
            Text(value, style: _h1(22)),
            const SizedBox(height: 2),
            Text(label, style: _body(11, c: t3)),
          ],
        ));

  Widget _legendDot(String label, int count, int total, Color color) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(
          '$label  $count  '
          '(${total == 0 ? 0 : (count * 100 / total).round()}%)',
          style: _body(12, c: t2, fw: FontWeight.w500),
        ),
      ]);

  Widget _engineFact(
          IconData icon, Color color, String title, String sub) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 13),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _body(13, c: t1, fw: FontWeight.w600)),
              Text(sub, style: _body(12)),
            ],
          )),
        ]),
      );

  // ════════════════════════════════════════════════════════════════════════
  //  ACTIONS
  // ════════════════════════════════════════════════════════════════════════
  Future<void> _runAnalysis() async {
    if (_inputText.trim().length < _minChars || _analyzing) return;
    FocusScope.of(context).unfocus();
    setState(() => _analyzing = true);
    HapticFeedback.lightImpact();

    try {
      await Future.delayed(const Duration(milliseconds: 480));
      if (!mounted) return;

      final result = _SentimentEngine.analyze(_inputText.trim());

      final entry = _HistoryEntry(
        id        : DateTime.now().millisecondsSinceEpoch.toString(),
        text      : _inputText.trim(),
        label     : result.label,
        score     : result.score,
        confidence: result.confidence,
        time      : DateTime.now(),
      );
      _history.add(entry);
      if (_history.length > _maxHistory) _history.removeAt(0);
      await _persistHistory();

      if (!mounted) return;
      setState(() { _result = result; _analyzing = false; });
      _revealCtrl.forward(from: 0.0);

    } catch (e) {
      if (!mounted) return;
      setState(() => _analyzing = false);
      _showToast('Analysis failed: $e', _C.red);
    }
  }

  void _clear() {
    _textCtrl.clear();
    setState(() { _inputText = ''; _result = null; });
    _focusNode.requestFocus();
  }

  void _copyResult(_SentimentResult r) {
    final text =
        'Sentiment: ${r.scoreLabel}\n'
        'Score: ${(r.score * 100).round()} / 100\n'
        'Confidence: ${(r.confidence * 100).round()}%\n'
        'Positive: ${(r.positive * 100).round()}%  '
        'Neutral: ${(r.neutral * 100).round()}%  '
        'Negative: ${(r.negative * 100).round()}%\n'
        'Keywords: ${r.keywords.map((k) => k.word).join(', ')}';
    Clipboard.setData(ClipboardData(text: text));
    _showToast('Result copied to clipboard', _C.green);
  }

  void _confirmClearHistory() {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Clear History?', style: _h2(16)),
        content: Text(
          'This will permanently delete all ${_history.length} entries.',
          style: _body(13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: _body(13, c: t2)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _history.clear());
              _persistHistory();
              _showToast('History cleared', _C.amber);
            },
            style: FilledButton.styleFrom(
              backgroundColor: _C.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Clear all',
                style: _body(13, c: Colors.white, fw: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  SHARED PRIMITIVES
  // ════════════════════════════════════════════════════════════════════════
  Widget _card({
    required Widget child,
    EdgeInsets? padding,
    Color? borderColor,
    Color? bgColor,
  }) =>
      Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bgColor ?? card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor ?? bdr),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: _dark ? 0.25 : 0.04),
            blurRadius: 12, offset: const Offset(0, 3),
          )],
        ),
        child: child,
      );

  Widget _sectionHeader(IconData icon, String title, Color color) =>
      Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 10),
        Text(title, style: _h2(14)),
      ]);

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.22)),
    ),
    child: Text(text, style: _body(11, c: color, fw: FontWeight.w600)),
  );

  Widget _emptyState(
          IconData icon, Color color, String title, String sub) =>
      _card(child: SizedBox(
        height: 280,
        child: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(title, style: _h2(16)),
            const SizedBox(height: 8),
            Text(sub,
                textAlign: TextAlign.center,
                style: _body(13, h: 1.55)),
          ],
        )),
      ));

  void _showToast(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg,
            style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  int _wordCount() => _inputText.trim().isEmpty
      ? 0
      : _inputText.trim().split(RegExp(r'\s+')).length;

  String _formatTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    return '${t.day}/${t.month}/${t.year}';
  }

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_saver/file_saver.dart';
import 'package:permission_handler/permission_handler.dart';

// ════════════════════════════════════════════════════════════════════════════
//  DESIGN TOKENS
// ════════════════════════════════════════════════════════════════════════════
class _C {
  static const blue      = Color(0xFF1A73E8);
  static const blueSoft  = Color(0xFFE8F0FE);
  static const green     = Color(0xFF1E8E3E);
  static const red       = Color(0xFFD93025);
  static const redSoft   = Color(0xFFFCE8E6);
  static const amber     = Color(0xFFF9AB00);
  static const purple    = Color(0xFF8430CE);
  static const teal      = Color(0xFF007B83);
  static const orange    = Color(0xFFFA7B17);

  // Light
  static const lBg    = Color(0xFFF8F9FA);
  static const lCard  = Color(0xFFFFFFFF);
  static const lBdr   = Color(0xFFDFE1E5);
  static const lT1    = Color(0xFF1F2328);
  static const lT2    = Color(0xFF5F6368);
  static const lT3    = Color(0xFF9AA0A6);

  // Dark
  static const dBg      = Color(0xFF1A1B1E);
  static const dCard    = Color(0xFF27282C);
  static const dCardAlt = Color(0xFF303134);
  static const dBdr     = Color(0xFF3C4043);
  static const dT1      = Color(0xFFE8EAED);
  static const dT2      = Color(0xFF9AA0A6);
  static const dT3      = Color(0xFF5F6368);

  static const List<Color> clusters = [
    blue, green, Color(0xFFD93025), amber, purple, teal, orange,
  ];
}

// ════════════════════════════════════════════════════════════════════════════
//  PAGE
// ════════════════════════════════════════════════════════════════════════════
class CustomerSegmentationPage extends StatefulWidget {
  const CustomerSegmentationPage({super.key});
  @override
  State<CustomerSegmentationPage> createState() =>
      _CustomerSegmentationPageState();
}

class _CustomerSegmentationPageState extends State<CustomerSegmentationPage>
    with TickerProviderStateMixin {

  // ── state ──────────────────────────────────────────────────────────────────
  bool   _loading  = false;
  double _progress = 0.0;
  int    _step     = 0;
  Map<String, dynamic>? _result;
  String? _error;
  String? _fileName;
  int?    _fileSize;
  bool    _dark    = false;
  bool    _hover   = false;
  List<String> _history = [];

  final _url = "https://miniproject-backend-2dqt.onrender.com/upload_csv/";

  // ── controllers ────────────────────────────────────────────────────────────
  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700));
    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.90, end: 1.10).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _loadPrefs();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── theme helpers ──────────────────────────────────────────────────────────
  Color get bg      => _dark ? _C.dBg      : _C.lBg;
  Color get card    => _dark ? _C.dCard    : _C.lCard;
  Color get cardAlt => _dark ? _C.dCardAlt : const Color(0xFFF1F3F4);
  Color get bdr     => _dark ? _C.dBdr     : _C.lBdr;
  Color get t1      => _dark ? _C.dT1      : _C.lT1;
  Color get t2      => _dark ? _C.dT2      : _C.lT2;
  Color get t3      => _dark ? _C.dT3      : _C.lT3;

  TextStyle _ts(double sz, {FontWeight fw = FontWeight.w400, Color? c,
      double? h, double? ls}) =>
      GoogleFonts.notoSans(fontSize: sz, fontWeight: fw,
          color: c ?? t1, height: h, letterSpacing: ls);

  // ════════════════════════════════════════════════════════════════════════
  //  PREFS
  // ════════════════════════════════════════════════════════════════════════
  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _dark    = p.getBool('dark_mode') ?? false;
      _history = p.getStringList('upload_history') ?? [];
    });
  }

  Future<void> _saveTheme(bool v) async =>
      (await SharedPreferences.getInstance()).setBool('dark_mode', v);

  // ════════════════════════════════════════════════════════════════════════
  //  UPLOAD
  // ════════════════════════════════════════════════════════════════════════
  Future<void> _pick() async {
    try {
      final r = await FilePicker.platform.pickFiles(
          type: FileType.custom, allowedExtensions: ['csv'], withData: true);
      if (r == null || r.files.isEmpty) return;
      final f = r.files.single;
      if (f.bytes == null) { _err("File is invalid or empty."); return; }
      setState(() { _fileName = f.name; _fileSize = f.size; });
      await _upload(f.bytes!, f.name);
    } catch (e) { _err("Failed to pick file: $e"); }
  }

  Future<void> _upload(Uint8List bytes, String name) async {
    if (!mounted) return;
    setState(() {
      _loading = true; _progress = 0; _step = 1;
      _result = null; _error = null;
    });

    Timer? t = Timer.periodic(const Duration(milliseconds: 350), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        _progress = (_progress + 0.055).clamp(0.0, 0.92);
        _step     = _progress < 0.35 ? 1 : _progress < 0.70 ? 2 : 3;
      });
    });

    try {
      final req = http.MultipartRequest('POST', Uri.parse(_url))
        ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: name));
      final res = await req.send().timeout(
        const Duration(seconds: 120),
        onTimeout: () => throw TimeoutException('Server timeout (120 s)'),
      );
      final body = await res.stream.bytesToString();

      if (res.statusCode == 200) {
        final data = jsonDecode(body) as Map<String, dynamic>? ?? {};
        if (mounted) {
          setState(() { _result = data; _progress = 1.0; _step = 4; });
          _fadeCtrl.forward(from: 0.0);
          _toast("Analysis completed successfully", _C.green,
              Icons.check_circle_outline);
        }
        await _saveHistory(name);
      } else {
        _err("Server error ${res.statusCode}\n$body");
      }
    } on TimeoutException catch (e) {
      _err(e.message ?? "Request timed out");
    } catch (e) {
      _err("Request failed: $e");
    } finally {
      t?.cancel();
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveHistory(String name) async {
    final p = await SharedPreferences.getInstance();
    final h = p.getStringList('upload_history') ?? [];
    h.add("${DateTime.now().toLocal().toString().split('.')[0]} — $name");
    if (h.length > 6) h.removeAt(0);
    await p.setStringList('upload_history', h);
    if (mounted) setState(() => _history = h);
  }

  void _err(String msg) {
    if (mounted) setState(() { _error = msg; _loading = false; });
  }

  // ════════════════════════════════════════════════════════════════════════
  //  DOWNLOAD SAMPLE CSV
  //  Uses file_saver → MediaStore API on Android (all versions, no special
  //  permissions needed). Falls back to legacy path on older Android.
  // ════════════════════════════════════════════════════════════════════════
  Future<void> _downloadSample() async {
    const csv =
        'CustomerID,Gender,Age,Annual Income (k\$),Spending Score (1-100)\n'
        '1,Male,19,15,39\n'
        '2,Male,21,15,81\n'
        '3,Female,20,16,6\n'
        '4,Female,23,16,77\n'
        '5,Female,31,17,40\n';

    try {
      final bytes = Uint8List.fromList(utf8.encode(csv));
      final fileName =
          'sample_customer_data_${DateTime.now().millisecondsSinceEpoch}';

      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        ext: 'csv',
        mimeType: MimeType.csv,
      );

      _toast("Saved to Downloads: $fileName.csv",
          _C.green, Icons.download_done_rounded);
    } catch (e) {
      _toast("Download failed: $e", _C.red, Icons.error_outline);
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  //  EXPORT CHART
  //  Same approach — file_saver handles Android 11+ via MediaStore.
  // ════════════════════════════════════════════════════════════════════════
  Future<void> _exportChart(String b64, String name) async {
    if (kIsWeb) {
      _toast("Right-click image → Save as", _C.lT2, Icons.info_outline);
      return;
    }

    try {
      final bytes    = base64Decode(b64);
      final fileName = '${name}_${DateTime.now().millisecondsSinceEpoch}';

      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        ext: 'png',
        mimeType: MimeType.png,
      );

      _toast("Saved to Downloads: $fileName.png",
          _C.green, Icons.download_done_rounded);
    } catch (e) {
      _toast("Export failed: $e", _C.red, Icons.error_outline);
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  //  TOAST
  // ════════════════════════════════════════════════════════════════════════
  void _toast(String msg, Color color, IconData icon) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 10),
          Flexible(child: Text(msg,
              style: GoogleFonts.notoSans(
                  color: Colors.white, fontSize: 13))),
        ]),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ));
  }

  String _fmtBytes(int? b) {
    if (b == null || b <= 0) return '0 B';
    const s = ['B', 'KB', 'MB', 'GB'];
    var i = 0; double v = b.toDouble();
    while (v >= 1024 && i < s.length - 1) { v /= 1024; i++; }
    return '${v.toStringAsFixed(1)} ${s[i]}';
  }

  // ════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: _appBar(),
      body: SafeArea(
        child: LayoutBuilder(builder: (_, c) {
          final wide = c.maxWidth > 860;
          final pad  = wide ? 48.0 : 20.0;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: pad, vertical: 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: wide ? _wideLayout() : _narrowLayout(),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _appBar() => AppBar(
    elevation: 0,
    scrolledUnderElevation: 1,
    backgroundColor: card,
    surfaceTintColor: Colors.transparent,
    titleSpacing: 20,
    title: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
            color: _C.blueSoft,
            borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.hub_rounded, color: _C.blue, size: 18),
      ),
      const SizedBox(width: 10),
      Flexible(
        child: Text("Customer Segmentation",
            overflow: TextOverflow.ellipsis,
            style: _ts(16, fw: FontWeight.w600)),
      ),
      const SizedBox(width: 8),
      _pill("ML", _C.blue),
    ]),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: bdr),
    ),
    actions: [
      _iconBtn(Icons.refresh_rounded, "Reset all", () => setState(() {
        _result = null; _error = null; _fileName = null;
        _fileSize = null; _progress = 0; _step = 0;
      })),
      _iconBtn(
        _dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        _dark ? "Light mode" : "Dark mode",
        () { setState(() => _dark = !_dark); _saveTheme(_dark); },
      ),
      const SizedBox(width: 8),
    ],
  );

  Widget _iconBtn(IconData icon, String tip, VoidCallback fn) => Tooltip(
    message: tip,
    child: InkWell(
      onTap: fn,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, color: t2, size: 20),
      ),
    ),
  );

  // ── Layouts ────────────────────────────────────────────────────────────────
  Widget _wideLayout() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _breadcrumb(), const SizedBox(height: 8),
        _header(),     const SizedBox(height: 28),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 5, child: Column(children: [
            _dropZone(),
            if (_fileName != null) ...[
              const SizedBox(height: 12), _fileChip()],
            const SizedBox(height: 12),
            _sampleRow(),
          ])),
          const SizedBox(width: 20),
          Expanded(flex: 3, child: Column(children: [
            _infoCard(),
            const SizedBox(height: 16),
            if (_history.isNotEmpty) _historyCard(),
          ])),
        ]),
        const SizedBox(height: 32),
        _resultArea(),
      ]);

  Widget _narrowLayout() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _breadcrumb(), const SizedBox(height: 8),
        _header(),     const SizedBox(height: 24),
        _dropZone(),
        if (_fileName != null) ...[const SizedBox(height: 12), _fileChip()],
        const SizedBox(height: 12),
        _sampleRow(),
        const SizedBox(height: 16),
        _infoCard(),
        if (_history.isNotEmpty) ...[
          const SizedBox(height: 16), _historyCard()],
        const SizedBox(height: 32),
        _resultArea(),
      ]);

  Widget _resultArea() {
    if (_loading)        return _progressCard();
    if (_error != null)  return _errorCard();
    if (_result != null) return FadeTransition(
        opacity: _fadeAnim, child: _dashboard());
    return const SizedBox.shrink();
  }

  // ── Page header ────────────────────────────────────────────────────────────
  Widget _breadcrumb() => Row(children: [
    Text("ML Tools", style: _ts(12, c: t2)),
    Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(Icons.chevron_right, size: 14, color: t3)),
    Text("Segmentation",
        style: _ts(12, c: _C.blue, fw: FontWeight.w500)),
  ]);

  Widget _header() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Customer Segmentation",
            style: _ts(26, fw: FontWeight.w700, ls: -0.5)),
        const SizedBox(height: 6),
        Text(
          "Upload a CSV dataset to automatically discover customer segments "
          "using K-Means clustering.",
          style: _ts(14, c: t2, h: 1.6),
        ),
      ]);

  // ── Drop zone ──────────────────────────────────────────────────────────────
  Widget _dropZone() {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: _loading ? null : _pick,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          decoration: BoxDecoration(
            color: _hover && !_loading
                ? (_dark
                    ? _C.dCardAlt
                    : _C.blueSoft.withValues(alpha: 0.45))
                : card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hover && !_loading ? _C.blue : bdr,
              width: _hover && !_loading ? 2.0 : 1.5,
            ),
            boxShadow: [BoxShadow(
              color: Colors.black.withValues(
                  alpha: _dark ? 0.20 : 0.05),
              blurRadius: 10, offset: const Offset(0, 3),
            )],
          ),
          child: Column(children: [
            ScaleTransition(
              scale: _loading
                  ? _pulseAnim
                  : const AlwaysStoppedAnimation(1.0),
              child: Container(
                width: 76, height: 76,
                decoration: BoxDecoration(
                  color: _C.blueSoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: _C.blue.withValues(alpha: 0.25), width: 2),
                ),
                child: Icon(
                  _loading
                      ? Icons.sync_rounded
                      : Icons.cloud_upload_outlined,
                  color: _C.blue, size: 34,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _loading ? "Uploading file…" : "Drop your CSV file here",
              style: _ts(17, fw: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            Text("or click to browse", style: _ts(13, c: t2)),
            const SizedBox(height: 20),
            Wrap(spacing: 8, runSpacing: 8,
                alignment: WrapAlignment.center, children: [
              _pill(".csv only", _C.blue),
              _pill("Numeric columns", _C.green),
              _pill("Max 50 MB", _C.amber),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: 190,
              child: FilledButton.icon(
                onPressed: _loading ? null : _pick,
                icon: const Icon(Icons.folder_open_rounded, size: 18),
                label: Text("Select File",
                    style: _ts(14, fw: FontWeight.w600, c: Colors.white)),
                style: FilledButton.styleFrom(
                  backgroundColor: _C.blue,
                  disabledBackgroundColor:
                      _C.blue.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── File chip ──────────────────────────────────────────────────────────────
  Widget _fileChip() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: _C.blueSoft,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _C.blue.withValues(alpha: 0.3)),
    ),
    child: Row(children: [
      const Icon(Icons.insert_drive_file_rounded,
          color: _C.blue, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_fileName ?? '',
            style: _ts(13, fw: FontWeight.w600, c: _C.blue),
            overflow: TextOverflow.ellipsis),
        Text(_fmtBytes(_fileSize),
            style: _ts(11, c: _C.blue.withValues(alpha: 0.65))),
      ])),
      GestureDetector(
        onTap: () => setState(() {
          _fileName = null; _fileSize = null;
        }),
        child: const Icon(Icons.close_rounded,
            color: _C.blue, size: 18),
      ),
    ]),
  );

  Widget _sampleRow() => Row(children: [
    TextButton.icon(
      onPressed: _downloadSample,
      icon: const Icon(Icons.download_rounded, size: 16, color: _C.blue),
      label: Text("Download sample CSV", style: _ts(13, c: _C.blue)),
      style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4)),
    ),
  ]);

  // ── Info card ──────────────────────────────────────────────────────────────
  Widget _infoCard() {
    const steps = [
      (Icons.upload_file_rounded,  _C.blue,   "Upload CSV",
          "Select a dataset with numeric columns"),
      (Icons.auto_awesome_mosaic,  _C.purple, "Auto Clustering",
          "K-Means groups similar customers automatically"),
      (Icons.bar_chart_rounded,    _C.green,  "Visual Insights",
          "Charts and statistics generated instantly"),
      (Icons.download_for_offline, _C.amber,  "Export Results",
          "Save charts as PNG for your report"),
    ];
    return _card(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.info_outline_rounded,
            size: 16, color: _C.blue),
        const SizedBox(width: 8),
        Text("How it works", style: _ts(14, fw: FontWeight.w600)),
      ]),
      Divider(height: 20, color: bdr),
      ...steps.asMap().entries.map((e) {
        final i = e.key; final s = e.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                  color: s.$2.withValues(alpha: 0.12),
                  shape: BoxShape.circle),
              child: Center(
                  child: Icon(s.$1, color: s.$2, size: 14)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text("${i + 1}. ${s.$3}",
                  style: _ts(13, fw: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(s.$4, style: _ts(12, c: t2, h: 1.4)),
            ])),
          ]),
        );
      }),
    ]));
  }

  // ── History card ───────────────────────────────────────────────────────────
  Widget _historyCard() => _card(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [
        const Icon(Icons.history_rounded, size: 16, color: _C.blue),
        const SizedBox(width: 8),
        Text("Recent Uploads", style: _ts(14, fw: FontWeight.w600)),
      ]),
      _pill("${_history.length}", _C.blue),
    ]),
    Divider(height: 20, color: bdr),
    ..._history.reversed.take(5).map((e) {
      final parts = e.split(' — ');
      final name  = parts.length > 1 ? parts[1] : e;
      final time  = parts.isNotEmpty ? parts[0] : '';
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
                color: _C.blueSoft,
                borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.insert_drive_file_outlined,
                color: _C.blue, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: _ts(12, fw: FontWeight.w500),
                overflow: TextOverflow.ellipsis),
            Text(time, style: _ts(11, c: t2)),
          ])),
        ]),
      );
    }),
  ]));

  // ── Progress card ──────────────────────────────────────────────────────────
  Widget _progressCard() {
    const labels = ["Uploading", "Processing", "Clustering", "Complete"];
    return _card(child: Column(children: [
      Row(children: [
        SizedBox(
          width: 22, height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: const AlwaysStoppedAnimation(_C.blue),
            backgroundColor: _C.blueSoft,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(
          _step > 0 && _step <= labels.length
              ? labels[_step - 1] : "Preparing…",
          style: _ts(14, fw: FontWeight.w500),
        )),
        Text(
          "${(_progress * 100).toStringAsFixed(0)}%",
          style: _ts(14, fw: FontWeight.w700, c: _C.blue),
        ),
      ]),
      const SizedBox(height: 14),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: _progress, minHeight: 6,
          backgroundColor: _C.blueSoft,
          valueColor: const AlwaysStoppedAnimation(_C.blue),
        ),
      ),
      const SizedBox(height: 20),
      Row(
        children: List.generate(labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            final done = (i ~/ 2) < (_step - 1);
            return Expanded(child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 18),
                color: done ? _C.blue : bdr));
          }
          final idx  = i ~/ 2;
          final done = idx < (_step - 1);
          final curr = idx == (_step - 1);
          return Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 12, height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? _C.blue
                    : curr
                        ? _C.blue.withValues(alpha: 0.5)
                        : bdr,
                border: Border.all(
                    color: done || curr ? _C.blue : bdr, width: 2),
              ),
            ),
            const SizedBox(height: 5),
            Text(labels[idx],
                style: _ts(10,
                    c: done || curr ? _C.blue : t3,
                    fw: curr
                        ? FontWeight.w600
                        : FontWeight.w400)),
          ]);
        }),
      ),
    ]));
  }

  // ── Error card ─────────────────────────────────────────────────────────────
  Widget _errorCard() => _card(
    borderColor: _C.red.withValues(alpha: 0.4),
    bgColor: _dark ? _C.dCard : _C.redSoft.withValues(alpha: 0.25),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: _C.redSoft, shape: BoxShape.circle),
          child: const Icon(Icons.error_outline_rounded,
              color: _C.red, size: 18),
        ),
        const SizedBox(width: 12),
        Text("Something went wrong",
            style: _ts(15, fw: FontWeight.w600, c: _C.red)),
      ]),
      const SizedBox(height: 14),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _C.red.withValues(alpha: 0.2)),
        ),
        child: SelectableText(
          _error ?? "Unknown error.",
          style: GoogleFonts.robotoMono(
              fontSize: 12, color: _C.red, height: 1.6),
        ),
      ),
      const SizedBox(height: 16),
      Row(children: [
        OutlinedButton(
          onPressed: () => setState(() => _error = null),
          style: OutlinedButton.styleFrom(
            foregroundColor: t2,
            side: BorderSide(color: bdr),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 11),
          ),
          child: Text("Dismiss", style: _ts(13)),
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: _pick,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: Text("Try Again", style: _ts(13, c: Colors.white)),
          style: FilledButton.styleFrom(
            backgroundColor: _C.blue,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 11),
          ),
        ),
      ]),
    ]),
  );

  // ════════════════════════════════════════════════════════════════════════
  //  RESULTS DASHBOARD
  // ════════════════════════════════════════════════════════════════════════
  Widget _dashboard() {
    final summary =
        _result?["cluster_summary"] as Map<String, dynamic>? ?? {};
    final counts =
        _result?["cluster_count"] as Map<String, dynamic>? ?? {};
    final charts =
        _result?["charts"] as Map<String, dynamic>? ?? {};
    final total = counts.values.fold<int>(
        0, (a, v) => a + (int.tryParse(v?.toString() ?? '') ?? 0));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Results",
              style: _ts(22, fw: FontWeight.w700, ls: -0.4)),
          Text("K-Means clustering completed",
              style: _ts(13, c: t2)),
        ])),
        _pill("✓  Done", _C.green),
      ]),
      const SizedBox(height: 24),

      _statStrip(total, counts.length, summary),
      const SizedBox(height: 28),

      if (summary.isNotEmpty) ...[
        _sectionHead("Cluster Profiles",
            "Mean feature values per segment",
            badge: "${summary.length} clusters"),
        const SizedBox(height: 12),
        _clusterTable(summary, counts),
        const SizedBox(height: 28),
      ],

      if (charts.isNotEmpty) ...[
        _sectionHead("Visualizations",
            "Pinch to zoom  •  Tap Export to save"),
        const SizedBox(height: 16),
        _chartGrid(charts),
      ],

      if (summary.isEmpty && counts.isEmpty && charts.isEmpty)
        _emptyState("No results returned. Try a different dataset."),

      const SizedBox(height: 48),
    ]);
  }

  // ── Stat strip ─────────────────────────────────────────────────────────────
  Widget _statStrip(int total, int segs, Map<String, dynamic> summary) {
    final features = summary.isEmpty
        ? 0
        : (summary.values.first?.toString() ?? '').split(',').length;
    final stats = [
      ("Total Customers", total.toString(),
          Icons.people_alt_outlined, _C.blue),
      ("Segments Found", segs.toString(),
          Icons.donut_small_outlined, _C.green),
      ("Features Used", features.toString(),
          Icons.table_chart_outlined, _C.purple),
      ("Algorithm", "K-Means",
          Icons.account_tree_outlined, _C.amber),
    ];
    return LayoutBuilder(builder: (_, c) {
      if (c.maxWidth > 540) {
        return Row(
            children: stats.asMap().entries.map((e) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    right: e.key < stats.length - 1 ? 12 : 0),
                child: _statCard(e.value.$1, e.value.$2,
                    e.value.$3, e.value.$4),
              ),
            )).toList());
      }
      return Wrap(
        spacing: 12, runSpacing: 12,
        children: stats.map((s) => SizedBox(
          width: (c.maxWidth - 12) / 2,
          child: _statCard(s.$1, s.$2, s.$3, s.$4),
        )).toList(),
      );
    });
  }

  Widget _statCard(
          String label, String value, IconData icon, Color color) =>
      _card(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 15),
              ),
              Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle)),
            ]),
            const SizedBox(height: 10),
            Text(value,
                style: _ts(22, fw: FontWeight.w700, ls: -0.5)),
            const SizedBox(height: 2),
            Text(label,
                style: _ts(11, c: t2, fw: FontWeight.w500)),
          ],
        ),
      );

  // ── Cluster table ──────────────────────────────────────────────────────────
  Widget _clusterTable(
      Map<String, dynamic> summary, Map<String, dynamic> counts) {
    final entries = summary.entries.toList();
    return _card(padding: EdgeInsets.zero, child: Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 13),
        decoration: BoxDecoration(
            color: cardAlt,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12))),
        child: Row(children: [
          Expanded(flex: 3,
              child: Text("SEGMENT",
                  style: _ts(11,
                      c: t2, fw: FontWeight.w700, ls: 0.8))),
          const SizedBox(width: 12),
          Expanded(flex: 1,
              child: Text("SIZE",
                  style: _ts(11,
                      c: t2, fw: FontWeight.w700, ls: 0.8))),
          const SizedBox(width: 12),
          Expanded(flex: 6,
              child: Text("PROFILE (mean values)",
                  style: _ts(11,
                      c: t2, fw: FontWeight.w700, ls: 0.8))),
        ]),
      ),
      Divider(height: 1, color: bdr),
      ...entries.asMap().entries.map((e) {
        final idx   = e.key;
        final key   = e.value.key;
        final value = e.value.value?.toString() ?? '—';
        final count = counts[key]?.toString() ?? '—';
        final color = _C.clusters[idx % _C.clusters.length];
        return Column(children: [
          _clusterRow(key, value, count, color, idx),
          if (idx < entries.length - 1)
            Divider(height: 1, color: bdr),
        ]);
      }),
    ]));
  }

  Widget _clusterRow(String key, String value, String count,
      Color color, int idx) =>
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 14),
        color: idx.isEven
            ? Colors.transparent
            : (_dark
                ? Colors.white.withValues(alpha: 0.02)
                : Colors.black.withValues(alpha: 0.012)),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 3, child: Row(children: [
            Container(
                width: 4, height: 36,
                decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text("Cluster $key",
                  style: _ts(13, fw: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              _pill("Seg ${idx + 1}", color),
            ])),
          ])),
          const SizedBox(width: 12),
          Expanded(flex: 1, child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(count,
                style: _ts(13, fw: FontWeight.w500),
                overflow: TextOverflow.ellipsis),
          )),
          const SizedBox(width: 12),
          Expanded(flex: 6, child: Text(value,
              style: GoogleFonts.robotoMono(
                  fontSize: 11.5, color: t2, height: 1.6))),
        ]),
      );

  // ── Charts ─────────────────────────────────────────────────────────────────
  Widget _chartGrid(Map<String, dynamic> charts) {
    const defs = {
      "scatter": ("Scatter Plot", Icons.scatter_plot_rounded,
          "Customer distribution in feature space"),
      "heatmap": ("Correlation Heatmap", Icons.grid_on_rounded,
          "Feature correlation matrix"),
      "boxplot": ("Feature Distribution",
          Icons.candlestick_chart_rounded,
          "Value spread per cluster"),
      "bar": ("Cluster Comparison", Icons.bar_chart_rounded,
          "Mean values across segments"),
    };
    final ws = defs.entries.map((e) {
      final b64 = charts[e.key]?.toString() ?? '';
      if (b64.isEmpty) return null;
      Uint8List? bytes;
      try { bytes = base64Decode(b64); } catch (_) { return null; }
      return _chartCard(
          e.value.$1, e.value.$2, e.value.$3, bytes!, b64, e.key);
    }).whereType<Widget>().toList();

    return LayoutBuilder(builder: (_, c) {
      if (c.maxWidth <= 680 || ws.length < 2) {
        return Column(children: ws
            .map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 16), child: w))
            .toList());
      }
      final rows = <Widget>[];
      for (var i = 0; i < ws.length; i += 2) {
        rows.add(Row(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: ws[i]),
          const SizedBox(width: 16),
          Expanded(child: i + 1 < ws.length
              ? ws[i + 1] : const SizedBox()),
        ]));
        if (i + 2 < ws.length) rows.add(const SizedBox(height: 16));
      }
      return Column(children: rows);
    });
  }

  Widget _chartCard(String title, IconData icon, String sub,
      Uint8List bytes, String b64, String key) =>
      _card(padding: EdgeInsets.zero, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: _C.blueSoft,
                  borderRadius: BorderRadius.circular(7)),
              child: Icon(icon, color: _C.blue, size: 14),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(title, style: _ts(13, fw: FontWeight.w600)),
              Text(sub, style: _ts(11, c: t2)),
            ])),
            InkWell(
              onTap: () => _exportChart(b64, key),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.download_rounded, size: 14, color: t2),
                  const SizedBox(width: 4),
                  Text("Export", style: _ts(11, c: t2)),
                ]),
              ),
            ),
          ]),
        ),
        Divider(height: 18, color: bdr),
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12)),
          child: InteractiveViewer(
            minScale: 0.7, maxScale: 5.0,
            child: Image.memory(bytes,
              fit: BoxFit.contain, width: double.infinity,
              errorBuilder: (_, __, ___) => Padding(
                padding: const EdgeInsets.all(48),
                child: Center(child: Icon(
                    Icons.broken_image_outlined,
                    size: 40, color: t3)),
              ),
            ),
          ),
        ),
      ]));

  // ════════════════════════════════════════════════════════════════════════
  //  PRIMITIVES
  // ════════════════════════════════════════════════════════════════════════
  Widget _card({required Widget child, EdgeInsets? padding,
      Color? borderColor, Color? bgColor}) =>
      Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor ?? card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor ?? bdr),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(
                alpha: _dark ? 0.20 : 0.05),
            blurRadius: 8, offset: const Offset(0, 2),
          )],
        ),
        child: child,
      );

  Widget _pill(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Text(text,
        style: _ts(11, c: color, fw: FontWeight.w600)),
  );

  Widget _sectionHead(String title, String sub, {String? badge}) =>
      Row(children: [
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: _ts(18, fw: FontWeight.w600, ls: -0.2)),
          const SizedBox(height: 2),
          Text(sub, style: _ts(12, c: t2)),
        ])),
        if (badge != null) _pill(badge, _C.blue),
      ]);

  Widget _emptyState(String msg) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 56),
    child: Center(child: Column(children: [
      Icon(Icons.inbox_outlined, size: 52, color: t3),
      const SizedBox(height: 14),
      Text(msg, style: _ts(14, c: t2),
          textAlign: TextAlign.center),
    ])),
  );
}
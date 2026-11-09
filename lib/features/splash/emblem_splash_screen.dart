import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _green = Color(0xFF0E5C3A);
const _paper = Color(0xFFFBF8F0);
const _gold = Color(0xFFC9A227);
const _goldDark = Color(0xFF94701A);

class ZankoEmblemSplash extends StatefulWidget {
  final VoidCallback onFinished;
  final String topText;
  final String bottomText;
  final Duration firstRunDuration;
  final Duration duration;
  const ZankoEmblemSplash({
    super.key,
    required this.onFinished,
    this.topText = 'ZANKOSWAP',
    this.bottomText = 'SWAP · SHARE · LEARN',
    this.firstRunDuration = const Duration(milliseconds: 6500),
    this.duration = const Duration(milliseconds: 3500),
  });

  static const _seenKey = 'emblem_splash_seen';

  @override
  State<ZankoEmblemSplash> createState() => _ZankoEmblemSplashState();
}

class _ZankoEmblemSplashState extends State<ZankoEmblemSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.firstRunDuration,
  );

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(ZankoEmblemSplash._seenKey) == true) {
        _c.duration = widget.duration;
      } else {
        await prefs.setBool(ZankoEmblemSplash._seenKey, true);
      }
    } catch (_) {}
    if (!mounted) return;
    _c.forward().whenComplete(() {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = math.min(MediaQuery.of(context).size.width * 0.82, 300.0);
    return Scaffold(
      backgroundColor: _paper,
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _BackgroundPainter(_c.value, s)),
            Center(
              child: SizedBox(
                width: s,
                height: s,
                child: CustomPaint(
                  painter: _EmblemPainter(
                    _c.value,
                    widget.topText,
                    widget.bottomText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _fade(Color color, double opacity) =>
    color.withValues(alpha: color.a * opacity);

class _BackgroundPainter extends CustomPainter {
  final double t, s;
  _BackgroundPainter(this.t, this.s);

  double _seg(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width, height = size.height;
    final rect = Offset.zero & size;
    final c = Offset(width / 2, height / 2);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(width / 2, height * .46),
          math.sqrt(width * width + height * height) / 2,
          const [Color(0xFFFFFDF7), Color(0xFFEEF4EE), Color(0xFFB7D2C3)],
          const [0.0, 0.45, 1.0],
        ),
    );

    final pa = .55 * _seg(0, .12);
    if (pa > 0) {
      const r = 22.0;
      final dx = r * math.sqrt(3), dy = r * 1.5;
      final hex = Path();
      for (var row = -1; row * dy < height + r; row++) {
        for (var col = -1; col * dx < width + dx; col++) {
          final cx = col * dx + (row.isOdd ? dx / 2 : 0), cy = row * dy;
          for (var i = 0; i <= 6; i++) {
            final a = -math.pi / 2 + i * math.pi / 3;
            final x = cx + math.cos(a) * r, y = cy + math.sin(a) * r;
            i == 0 ? hex.moveTo(x, y) : hex.lineTo(x, y);
          }
        }
      }
      canvas.drawPath(
        hex,
        Paint()
          ..color = _fade(_green, .09 * pa)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(c, s * .75, const [
          Color(0xFFFFFDF7),
          Color(0x00FFFDF7),
        ]),
    );

    final halo = Curves.easeOutCubic.transform(_seg(.55, .66));
    if (halo > 0) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.radial(
            c,
            s * .78,
            [
              _fade(const Color(0xFFE8C76A), .5 * halo),
              const Color(0x00E8C76A),
            ],
            const [0.26, 1.0],
          ),
      );
    }

    final rnd = math.Random(7);
    final dustIn = _seg(.02, .15);
    for (var i = 0; i < 34; i++) {
      final x0 = rnd.nextDouble() * width;
      final sp = .25 + rnd.nextDouble() * .6;
      final ph = rnd.nextDouble();
      final sz = .8 + rnd.nextDouble() * 2.2;
      final y = ((ph - t * sp) % 1) * height;
      final x = x0 + math.sin(t * 6 + ph * 10) * 8;
      final a = (.25 + .45 * math.sin(t * 9 + i).abs()) * dustIn;
      if (a <= 0) continue;
      canvas.drawCircle(Offset(x, y), sz, Paint()..color = _fade(_gold, a));
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => old.t != t || old.s != s;
}

class _Poly {
  final List<Offset> pts;
  final List<double> acc = [0];
  late final double len;
  _Poly(this.pts) {
    for (var i = 1; i < pts.length; i++) {
      acc.add(acc[i - 1] + (pts[i] - pts[i - 1]).distance);
    }
    len = acc.last;
  }

  Offset at(double d) {
    d = d.clamp(0.0, len);
    var i = 1;
    while (i < acc.length - 1 && acc[i] < d) {
      i++;
    }
    final seg = (acc[i] - acc[i - 1]) == 0 ? 1.0 : acc[i] - acc[i - 1];
    return Offset.lerp(pts[i - 1], pts[i], (d - acc[i - 1]) / seg)!;
  }

  Path trace(double from, double to) {
    final s = at(from);
    final p = Path()..moveTo(s.dx, s.dy);
    for (var i = 0; i < pts.length; i++) {
      if (acc[i] > from && acc[i] < to) p.lineTo(pts[i].dx, pts[i].dy);
    }
    final e = at(to);
    return p..lineTo(e.dx, e.dy);
  }
}

List<Offset> _quad(Offset a, Offset b, Offset c, [int n = 30]) => [
  for (var i = 0; i <= n; i++)
    () {
      final t = i / n, u = 1 - t;
      return a * (u * u) + b * (2 * u * t) + c * (t * t);
    }(),
];

List<Offset> _line(Offset a, Offset b, [int n = 30]) => [
  for (var i = 0; i <= n; i++) Offset.lerp(a, b, i / n)!,
];

class _EmblemPainter extends CustomPainter {
  final double t;
  final String top, bottom;
  _EmblemPainter(this.t, this.top, this.bottom);

  double _seg(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  void _alpha(Canvas c, double a, void Function() draw) {
    if (a <= 0) return;
    if (a >= 1) return draw();
    c.saveLayer(null, Paint()..color = _fade(Colors.white, a));
    draw();
    c.restore();
  }

  Path _star5(Offset c, double r) {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final rr = i.isOdd ? r * .45 : r;
      final a = -math.pi / 2 + i * math.pi / 5;
      final o = c + Offset(math.cos(a), math.sin(a)) * rr;
      i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    return p..close();
  }

  List<Offset> _hex(double c, double r) => [
    for (var i = 0; i <= 6; i++)
      Offset(
        c + math.cos(-math.pi / 2 + i * math.pi / 3) * r,
        c + math.sin(-math.pi / 2 + i * math.pi / 3) * r,
      ),
  ];

  void _rope(Canvas canvas, Offset c, double r, double prog, double k) {
    if (prog <= 0) return;
    final a0 = -math.pi / 2, sweep = math.pi * 2 * prog;
    final thin = Paint()
      ..color = _gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1 * k;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - 2 * k),
      a0,
      sweep,
      false,
      thin,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r + 2 * k),
      a0,
      sweep,
      false,
      thin,
    );
    final ticks = Path();
    const step = math.pi / 80;
    for (var a = a0; a < a0 + sweep; a += step) {
      final p1 = c + Offset(math.cos(a), math.sin(a)) * (r - 2 * k);
      final p2 =
          c +
          Offset(math.cos(a + step * .8), math.sin(a + step * .8)) *
              (r + 2 * k);
      ticks
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy);
    }
    canvas.drawPath(ticks, thin..strokeWidth = 1.3 * k);
  }

  void _quill(Canvas canvas, Offset tip, double ang, double length, double k) {
    canvas.save();
    canvas.translate(tip.dx, tip.dy);
    canvas.rotate(ang);
    final w = length * .19;
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(length * .45, -w * 1.5, length, -w * .25)
        ..quadraticBezierTo(length * .55, w * .95, length * .16, w * .14)
        ..close(),
      Paint()..color = _green,
    );
    final line = Paint()
      ..color = _paper
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.1 * k;
    canvas.drawPath(
      Path()
        ..moveTo(length * .12, 0)
        ..quadraticBezierTo(length * .55, -w * .25, length * .96, -w * .27),
      line,
    );
    line.strokeWidth = 1.6 * k;
    canvas.drawLine(
      Offset(length * .5, -w * .2),
      Offset(length * .58, -w * .95),
      line,
    );
    canvas.drawLine(
      Offset(length * .68, -w * .24),
      Offset(length * .62, w * .5),
      line,
    );
    canvas.restore();
  }

  void _curvedText(
    Canvas canvas,
    Offset c,
    double r,
    String txt,
    TextStyle style,
    double spacing,
    int dir,
    double shown,
    int base,
  ) {
    final chars = txt.split('');
    final painters = [
      for (final ch in chars)
        TextPainter(
          text: TextSpan(text: ch, style: style),
          textDirection: TextDirection.ltr,
        )..layout(),
    ];
    final total =
        painters.fold<double>(0, (s, p) => s + p.width) +
        spacing * (chars.length - 1);
    var cum = 0.0;
    for (var i = 0; i < chars.length; i++) {
      final tp = painters[i];
      final al = (shown - base - i).clamp(0.0, 1.0);
      final a =
          (dir > 0 ? -math.pi / 2 : math.pi / 2) +
          dir * (cum + tp.width / 2 - total / 2) / r;
      cum += tp.width + spacing;
      if (al <= 0) continue;
      final faded = TextPainter(
        text: TextSpan(
          text: chars[i],
          style: style.copyWith(color: _fade(style.color!, al)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
      canvas.rotate(a + dir * math.pi / 2);
      faded.paint(canvas, Offset(-faded.width / 2, -faded.height / 2));
      canvas.restore();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final dim = size.width, k = dim / 300, mid = dim / 2;
    final center = Offset(mid, mid);

    final pBook = _seg(.03, .20);
    final pFill = Curves.easeOutCubic.transform(_seg(.17, .25));
    final pRest = Curves.easeInOut.transform(_seg(.19, .26));
    final pSwap = Curves.easeOutBack.transform(_seg(.24, .32));
    final pRope = Curves.easeInOut.transform(_seg(.30, .42));
    final pStars = _seg(.30, .42);
    final pStarsOut = Curves.easeIn.transform(_seg(.46, .55));
    final pText = _seg(.42, .56);
    final pRos = Curves.easeOutBack.transform(_seg(.55, .64));
    final pHex = Curves.easeInOut.transform(_seg(.63, .73));
    final pShine = Curves.easeInOut.transform(_seg(.73, .84));
    final pSpark = _seg(.79, .91);
    final out = _seg(.93, 1.0);

    _alpha(canvas, 1 - out, () {
      if (pHex > 0) {
        final o = _Poly(_hex(mid, .5 * dim)), i = _Poly(_hex(mid, .475 * dim));
        final p = Paint()
          ..color = _gold
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(o.trace(0, o.len * pHex), p..strokeWidth = 2.8 * k);
        canvas.drawPath(
          i.trace(0, i.len * pHex),
          p
            ..color = _green
            ..strokeWidth = 1.1 * k,
        );
      }

      if (pRos > 0) {
        final radius = .395 * dim * (.72 + .28 * pRos);
        final amp = .02 * dim * math.max(0.0, pRos);
        final seal = Path();
        for (var i = 0; i <= 240; i++) {
          final a = i / 240 * math.pi * 2, r = radius + amp * math.cos(12 * a);
          final o = center + Offset(math.cos(a), math.sin(a)) * r;
          i == 0 ? seal.moveTo(o.dx, o.dy) : seal.lineTo(o.dx, o.dy);
        }
        seal.close();
        _alpha(canvas, (pRos * 1.5).clamp(0.0, 1.0), () {
          canvas.drawShadow(seal, Colors.black, 4 * k, false);
          canvas.drawPath(
            seal,
            Paint()
              ..shader = ui.Gradient.radial(
                Offset(mid, mid * .8),
                radius + amp,
                const [Color(0xFF1F8A5A), _green, Color(0xFF0A4329)],
                const [0.0, 0.7, 1.0],
              ),
          );
          canvas.drawPath(
            seal,
            Paint()
              ..color = _gold
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4 * k,
          );
        });
        _alpha(canvas, (pRos * 3).clamp(0.0, 1.0), () {
          canvas.drawCircle(
            center,
            math.min(.362 * dim, radius),
            Paint()..color = _paper,
          );
        });
      }

      _rope(canvas, center, .345 * dim, pRope, k);
      _rope(canvas, center, .245 * dim, pRope, k);

      final starPaint = Paint()..color = _gold;
      if (pStars > 0 && pStarsOut < 1) {
        final rot = (1 - Curves.easeOutCubic.transform(pStars)) * -1.6;
        final r = (.46 + (.295 - .46) * pStarsOut) * dim;
        final sz =
            .024 * dim * math.max(0.0, Curves.easeOutBack.transform(pStars));
        _alpha(canvas, (1 - pStarsOut) * math.min(1.0, pStars * 2), () {
          for (var i = 0; i < 16; i++) {
            final a = rot + i * math.pi * 2 / 16;
            canvas.drawPath(
              _star5(center + Offset(math.cos(a), math.sin(a)) * r, sz),
              starPaint,
            );
          }
        });
      }
      _alpha(canvas, pStarsOut, () {
        canvas.drawPath(
          _star5(Offset(mid - .295 * dim, mid), .02 * dim),
          starPaint,
        );
        canvas.drawPath(
          _star5(Offset(mid + .295 * dim, mid), .02 * dim),
          starPaint,
        );
      });

      if (pText > 0) {
        final shown = pText * (top.length + bottom.length);
        _curvedText(
          canvas,
          center,
          .295 * dim,
          top,
          TextStyle(
            color: _green,
            fontSize: .052 * dim,
            fontWeight: FontWeight.w800,
          ),
          .012 * dim,
          1,
          shown,
          0,
        );
        _curvedText(
          canvas,
          center,
          .295 * dim,
          bottom,
          TextStyle(
            color: _goldDark,
            fontSize: .036 * dim,
            fontWeight: FontWeight.w700,
          ),
          .006 * dim,
          -1,
          shown,
          top.length,
        );
      }

      canvas.save();
      canvas.translate(mid, mid);
      canvas.scale(.8);
      canvas.translate(-mid, -mid * 1.04);
      Offset pos(double x, double y) => Offset(x * dim, y * dim);

      final outline = _Poly([
        ..._quad(pos(.5, .665), pos(.41, .63), pos(.32, .645)),
        ..._line(pos(.32, .645), pos(.32, .505)).skip(1),
        ..._quad(pos(.32, .505), pos(.42, .49), pos(.5, .53)).skip(1),
        ..._line(pos(.5, .53), pos(.5, .665)).skip(1),
        ..._quad(pos(.5, .665), pos(.59, .63), pos(.68, .645)).skip(1),
        ..._line(pos(.68, .645), pos(.68, .505)).skip(1),
        ..._quad(pos(.68, .505), pos(.58, .49), pos(.5, .53)).skip(1),
      ]);
      final cover = _Poly([
        ..._line(pos(.295, .52), pos(.295, .668)),
        ..._quad(pos(.295, .668), pos(.42, .66), pos(.5, .70)).skip(1),
        ..._quad(pos(.5, .70), pos(.58, .66), pos(.705, .668)).skip(1),
        ..._line(pos(.705, .668), pos(.705, .52)).skip(1),
      ]);
      final ink = Paint()
        ..color = _green
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (pFill > 0) {
        canvas.drawPath(
          cover.trace(0, cover.len * pFill),
          ink..strokeWidth = 5 * k,
        );
        ink.strokeWidth = 2 * k;
        for (var i = 0; i < 3; i++) {
          final q = ((pFill - i * .2) / .5).clamp(0.0, 1.0);
          if (q <= 0) continue;
          final y = .555 + i * .028;
          for (final page in const [
            [.35, .47],
            [.53, .65],
          ]) {
            final a = page[0], b = page[1];
            final left = a < .5;
            final pl = _Poly(
              _quad(
                pos(a, y + (left ? .004 : -.008)),
                pos((a + b) / 2, y - .012),
                pos(b, y + (left ? -.008 : .004)),
              ),
            );
            canvas.drawPath(pl.trace(0, pl.len * q), ink);
          }
        }
      }

      final drawn = outline.len * Curves.easeInOut.transform(pBook);
      if (pBook > 0) {
        canvas.drawPath(outline.trace(0, drawn), ink..strokeWidth = 2.8 * k);
      }

      if (pSwap > 0) {
        final sc = pos(.5, .395), r = .052 * dim * pSwap, h = 9 * k * pSwap;
        final fill = Paint()..color = _gold;
        ink
          ..color = _gold
          ..strokeWidth = 4.5 * k * math.max(.01, pSwap);
        for (final arc in const [
          [205.0, 335.0],
          [25.0, 155.0],
        ]) {
          final s = arc[0] * math.pi / 180, e = arc[1] * math.pi / 180;
          canvas.drawArc(
            Rect.fromCircle(center: sc, radius: r.abs()),
            s,
            e - s,
            false,
            ink,
          );
          final end = sc + Offset(math.cos(e), math.sin(e)) * r;
          final d = e + math.pi / 2;
          Offset pt(double an, double rr) =>
              end + Offset(math.cos(an), math.sin(an)) * rr;
          final a1 = pt(d, h),
              a2 = pt(d + 2.4, h * .8),
              a3 = pt(d - 2.4, h * .8);
          canvas.drawPath(
            Path()
              ..moveTo(a1.dx, a1.dy)
              ..lineTo(a2.dx, a2.dy)
              ..lineTo(a3.dx, a3.dy)
              ..close(),
            fill,
          );
        }
      }

      final qa = _seg(0, .04);
      final tip = Offset.lerp(outline.at(drawn), pos(.555, .615), pRest)!;
      _alpha(canvas, qa, () => _quill(canvas, tip, -1.0, .26 * dim, k));
      canvas.restore();

      if (pShine > 0 && pShine < 1) {
        final hex = _hex(mid, .5 * dim);
        final clip = Path()..addPolygon(hex, true);
        canvas.save();
        canvas.clipPath(clip);
        canvas.translate(mid, mid);
        canvas.rotate(-.45);
        final x = (-1 + 2.2 * pShine) * dim;
        canvas.drawRect(
          Rect.fromLTWH(x - .18 * dim, -dim, .36 * dim, 2 * dim),
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(x - .18 * dim, 0),
              Offset(x + .18 * dim, 0),
              [
                _fade(Colors.white, 0),
                _fade(Colors.white, .55),
                _fade(Colors.white, 0),
              ],
              [0, .5, 1],
            ),
        );
        canvas.restore();
      }

      if (pSpark > 0 && pSpark < 1) {
        final s = math.sin(math.pi * pSpark) * 16 * k;
        final v = _hex(mid, .5 * dim)[1];
        canvas.save();
        canvas.translate(v.dx, v.dy);
        canvas.rotate(pSpark * 1.2);
        canvas.drawCircle(
          Offset.zero,
          s * 1.4,
          Paint()
            ..shader = ui.Gradient.radial(Offset.zero, s * 1.4, [
              const Color(0xE6FFECAA),
              const Color(0x00FFECAA),
            ]),
        );
        final sp = Path();
        for (var i = 0; i < 8; i++) {
          final r = i.isOdd ? s * .18 : s, a = i * math.pi / 4;
          final o = Offset(math.cos(a), math.sin(a)) * r;
          i == 0 ? sp.moveTo(o.dx, o.dy) : sp.lineTo(o.dx, o.dy);
        }
        canvas.drawPath(sp..close(), Paint()..color = const Color(0xFFFFFBE8));
        canvas.restore();
      }
    });
  }

  @override
  bool shouldRepaint(_EmblemPainter old) => old.t != t;
}

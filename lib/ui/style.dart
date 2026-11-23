import 'package:flutter/material.dart';

const ink = Color(0xff141321);
const panel = Color(0xff201e30);
const line = Color(0xff3b374e);
const muted = Color(0xffbbb6cd);
const paper = Color(0xfff6f2ff);
const lime = Color(0xffb4f6a7);
const violet = Color(0xffc5b4ff);

TextStyle headline(double size, [Color color = paper]) => TextStyle(
  fontFamily: 'Barlow Condensed',
  fontSize: size,
  height: 1.04,
  fontWeight: FontWeight.w700,
  color: color,
);

ThemeData appTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: lime,
    brightness: Brightness.dark,
  ).copyWith(surface: ink, primary: lime, onPrimary: ink, outline: line);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: ink,
    fontFamily: 'Roboto',
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: panel,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: line),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      prefixIconColor: muted,
      suffixIconColor: muted,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: lime,
        foregroundColor: ink,
        minimumSize: const Size(0, 48),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

class BrandBar extends StatelessWidget {
  const BrandBar({super.key, this.trailing, this.back = false});
  final Widget? trailing;
  final bool back;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 60,
    child: Row(
      children: [
        if (back)
          IconButton(
            tooltip: 'Voltar',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        const Icon(Icons.center_focus_strong_rounded, color: lime, size: 27),
        const SizedBox(width: 8),
        Text('PIXEL RADAR', style: headline(24).copyWith(letterSpacing: 1.3)),
        const Spacer(),
        ?trailing,
      ],
    ),
  );
}

class ArcadeBanner extends StatelessWidget {
  const ArcadeBanner({
    super.key,
    required this.title,
    required this.label,
    this.height = 150,
  });
  final String title, label;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: height),
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 17),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/arcade.png'),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: ink.withValues(alpha: .9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: Text(
                label,
                style: const TextStyle(
                  color: lime,
                  fontSize: 10,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: headline(40).copyWith(
              shadows: const [
                Shadow(
                  blurRadius: 10,
                  color: Colors.black,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

void message(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

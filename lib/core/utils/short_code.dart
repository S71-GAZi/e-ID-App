import 'dart:math';

/// Short, unguessable public slugs for card links (/c/<code>).
///
/// 12 chars from a 32-symbol alphabet ≈ 32^12 ≈ 2^60 possibilities —
/// effectively impossible to enumerate. Alphabet excludes look-alike
/// characters (0/o, 1/l/i) so codes are easy to read aloud.
class ShortCode {
  const ShortCode._();

  static const String _alphabet =
      'abcdefghjkmnpqrstuvwxyz23456789';
  static const int _length = 12;
  static final Random _random = Random.secure();

  static String generate([int length = _length]) => List.generate(
        length,
        (_) => _alphabet[_random.nextInt(_alphabet.length)],
      ).join();

  /// Basic shape validation (not a security check — the DB unique index is).
  static bool isValid(String code) => RegExp(
        '^[$_alphabet]{${_length - 4},$_length}\$') // allow legacy shorter codes
        .hasMatch(code);
}

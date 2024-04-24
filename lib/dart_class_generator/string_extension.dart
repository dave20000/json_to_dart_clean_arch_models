import 'dart:convert';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }

  String toCamelCase() {
    String capitalize(Match m) =>
        m[0]!.substring(0, 1).toUpperCase() + m[0]!.substring(1);
    String skip(String s) => "";
    return splitMapJoin(RegExp(r'[a-zA-Z0-9]+'),
        onMatch: capitalize, onNonMatch: skip);
  }

  String toCamelCaseFirstLower() {
    final camelCaseText = toCamelCase();
    final firstChar = camelCaseText.substring(0, 1).toLowerCase();
    final rest = camelCaseText.substring(1);
    return '$firstChar$rest';
  }

  String toSnakeCase() {
    StringBuffer snakeCase = StringBuffer();

    for (int i = 0; i < length; i++) {
      String currentChar = this[i];
      String? nextChar = i + 1 < length ? this[i + 1] : null;

      if (currentChar == ' ') {
        snakeCase.write('_');
      } else if (currentChar != '_' &&
          nextChar != null &&
          nextChar.toUpperCase() == nextChar) {
        snakeCase.write(currentChar.toLowerCase());
        snakeCase.write('_');
      } else {
        snakeCase.write(currentChar.toLowerCase());
      }
    }

    return snakeCase.toString();
  }

  dynamic get decodeJSON {
    return json.decode(this);
  }

  String toFirstCharLowerCase() {
    return "${this[0].toLowerCase()}${substring(1)}";
  }
}

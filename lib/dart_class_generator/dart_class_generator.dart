import 'dart:collection';

import '../json_ast/json_ast.dart' show parse, Settings, Node;
import 'dart_code.dart';
import 'helpers.dart';
import 'string_extension.dart';
import 'syntax.dart';

class DartClassGenerator {
  final String _rootClassName;
  final List<ClassDefinition> allClasses = <ClassDefinition>[];
  final Map<String, String> sameClassMapping = HashMap<String, String>();
  late List<Hint> hints;

  DartClassGenerator(
    this._rootClassName, [
    hints,
  ]) {
    if (hints != null) {
      this.hints = hints;
    } else {
      this.hints = <Hint>[];
    }
  }

  Hint? _hintForPath(String path) {
    final hint =
        hints.firstWhere((h) => h.path == path, orElse: () => Hint("", ""));
    if (hint.path == "") {
      return null;
    }
    return null;
  }

  List<Warning> _generateClassDefinition(
    String className,
    dynamic jsonRawDynamicData,
    String path,
    Node? astNode,
  ) {
    List<Warning> warnings = <Warning>[];
    if (jsonRawDynamicData is List) {
      // if first element is an array, start in the first element.
      final node = navigateNode(astNode, '0');
      _generateClassDefinition(className, jsonRawDynamicData[0], path, node!);
    } else {
      final Map<dynamic, dynamic> jsonRawData = jsonRawDynamicData;
      final keys = jsonRawData.keys;
      ClassDefinition classDefinition = ClassDefinition(
        name: className,
      );
      for (var key in keys) {
        TypeDefinition typeDef;
        final hint = _hintForPath('$path/$key');
        final node = navigateNode(astNode, key);
        if (hint != null) {
          typeDef = TypeDefinition(hint.type, astNode: node);
        } else {
          typeDef = TypeDefinition.fromDynamic(jsonRawData[key], node);
        }
        if (typeDef.name == 'Class') {
          typeDef.name = (key as String).toCamelCase();
        }
        if (typeDef.name == 'List' && typeDef.subtype == 'Null') {
          warnings.add(newEmptyListWarn('$path/$key'));
        }
        if (typeDef.subtype != null && typeDef.subtype == 'Class') {
          typeDef.subtype = (key as String).toCamelCase();
        }
        if (typeDef.isAmbiguous) {
          warnings.add(newAmbiguousListWarn('$path/$key'));
        }
        classDefinition.addField(key, typeDef);
      }
      final similarClass = allClasses.firstWhere(
        (cd) => cd == classDefinition,
        orElse: () => ClassDefinition(
          name: "",
        ),
      );
      if (similarClass.name != "") {
        final similarClassName = similarClass.name;
        final currentClassName = classDefinition.name;
        sameClassMapping[currentClassName] = similarClassName;
      } else {
        allClasses.add(classDefinition);
      }
      final dependencies = classDefinition.dependencies;
      for (var dependency in dependencies) {
        List<Warning> warns = <Warning>[];
        if (dependency.typeDef.name == 'List') {
          // only generate dependency class if the array is not empty
          if (jsonRawData[dependency.name].length > 0) {
            // when list has ambiguous values, take the first one, otherwise merge all objects
            // into a single one
            dynamic toAnalyze;
            if (!dependency.typeDef.isAmbiguous) {
              WithWarning<Map> mergeWithWarning = mergeObjectList(
                  jsonRawData[dependency.name], '$path/${dependency.name}');
              toAnalyze = mergeWithWarning.result;
              warnings.addAll(mergeWithWarning.warnings);
            } else {
              toAnalyze = jsonRawData[dependency.name][0];
            }
            final node = navigateNode(astNode, dependency.name);
            warns = _generateClassDefinition(dependency.className, toAnalyze,
                '$path/${dependency.name}', node);
          }
        } else {
          final node = navigateNode(astNode, dependency.name);
          warns = _generateClassDefinition(dependency.className,
              jsonRawData[dependency.name], '$path/${dependency.name}', node);
        }
        warnings.addAll(warns);
      }
    }
    return warnings;
  }

  /// generateUnsafeDart will generate all classes and append one after another
  /// in a single string. The [rawJson] param is assumed to be a properly
  /// formatted JSON string. The dart code is not validated so invalid dart code
  /// might be returned
  List<Warning> _generateUnsafeDart(String rawJson) {
    final jsonRawData = rawJson.decodeJSON;
    final astNode = parse(rawJson, Settings());
    List<Warning> warnings =
        _generateClassDefinition(_rootClassName, jsonRawData, "", astNode);
    // after generating all classes, replace the omited similar classes.
    for (var c in allClasses) {
      final fieldsKeys = c.fields.keys;
      for (var f in fieldsKeys) {
        final typeForField = c.fields[f];
        if (typeForField != null) {
          if (sameClassMapping.containsKey(typeForField.name)) {
            c.fields[f]!.name = sameClassMapping[typeForField.name]!;
          }
        }
      }
    }
    return warnings;
  }

  /// generateDartClasses will generate all classes and append one after another
  /// in a single string. The [rawJson] param is assumed to be a properly
  /// formatted JSON string. If the generated dart is invalid it will throw an error.
  DartCode generateApiDtoClasses(String rawJson) {
    List<Warning> warnings = _generateUnsafeDart(rawJson);
    final unsafeDartCode =
        DartCode(allClasses.map((c) => c.apiDto).join('\n'), warnings);
    return DartCode(
      unsafeDartCode.code,
      unsafeDartCode.warnings,
    );
  }

  DartCode generateUIModelClasses(String rawJson) {
    List<Warning> warnings = _generateUnsafeDart(rawJson);
    final unsafeDartCode =
        DartCode(allClasses.map((c) => c.uiModel).join('\n'), warnings);
    return DartCode(
      unsafeDartCode.code,
      unsafeDartCode.warnings,
    );
  }

  DartCode generateApiCacheDtoClasses(String rawJson) {
    List<Warning> warnings = _generateUnsafeDart(rawJson);
    final unsafeDartCode =
        DartCode(allClasses.map((c) => c.apiCacheDto).join('\n'), warnings);
    return DartCode(
      unsafeDartCode.code,
      unsafeDartCode.warnings,
    );
  }

  DartCode generateCacheDtoClasses(String rawJson) {
    List<Warning> warnings = _generateUnsafeDart(rawJson);
    final unsafeDartCode =
        DartCode(allClasses.map((c) => c.cacheDto).join('\n'), warnings);
    return DartCode(
      unsafeDartCode.code,
      unsafeDartCode.warnings,
    );
  }

  DartCode generateUICacheDtoClasses(String rawJson) {
    List<Warning> warnings = _generateUnsafeDart(rawJson);
    final unsafeDartCode =
        DartCode(allClasses.map((c) => c.uiCacheModel).join('\n'), warnings);
    return DartCode(
      unsafeDartCode.code,
      unsafeDartCode.warnings,
    );
  }
}

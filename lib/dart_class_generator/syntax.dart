import '../json_ast/json_ast.dart';
import 'helpers.dart';
import 'string_extension.dart';

class ClassDefinition {
  final String name;

  ClassDefinition({required this.name});

  final Map<String, TypeDefinition> fields = <String, TypeDefinition>{};
  List<Dependency> get dependencies {
    final dependenciesList = <Dependency>[];
    final keys = fields.keys;
    for (var k in keys) {
      final f = fields[k];
      if (f != null && !f.isPrimitive) {
        dependenciesList.add(Dependency(k, f));
      }
    }
    return dependenciesList;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;

    if (other is ClassDefinition) {
      ClassDefinition otherClassDef = other;
      return isSubsetOf(otherClassDef) && otherClassDef.isSubsetOf(this);
    }
    return false;
  }

  @override
  int get hashCode {
    return name.hashCode ^ fields.hashCode;
  }

  bool isSubsetOf(ClassDefinition other) {
    final List<String> keys = fields.keys.toList();
    final int len = keys.length;
    for (int i = 0; i < len; i++) {
      TypeDefinition? otherTypeDef = other.fields[keys[i]];
      if (otherTypeDef != null) {
        TypeDefinition? typeDef = fields[keys[i]];
        if (typeDef != otherTypeDef) {
          return false;
        }
      } else {
        return false;
      }
    }
    return true;
  }

  bool hasField(TypeDefinition otherField) {
    final key = fields.keys
        .firstWhere((k) => fields[k] == otherField, orElse: () => "");
    return key != "";
  }

  void addField(String name, TypeDefinition typeDef) {
    fields[name] = typeDef;
  }

  void _addTypeSyntaxString(
    TypeDefinition typeDef,
    StringBuffer sb, {
    required bool isModel,
    required bool isCacheDto,
    String? jsonKey,
  }) {
    if (!isModel && !isCacheDto && jsonKey != null) {
      sb.write('@JsonKey(name: "$jsonKey") ');
    }

    if (typeDef.name == "List") {
      sb.write("final List");
    } else {
      if (typeDef.isPrimitive || isModel) {
        sb.write("final ${typeDef.name}");
      } else if (isCacheDto) {
        sb.write(
            "final ${typeDef.name.endsWith("CacheDto") ? typeDef.name : "${typeDef.name}CacheDto"}");
      } else {
        sb.write(
            "final ${typeDef.name.endsWith("ApiDto") ? typeDef.name : "${typeDef.name}ApiDto"}");
      }
    }
    if (typeDef.subtype != null) {
      if (typeDef.isSubTypePrimitive || isModel) {
        sb.write('<${typeDef.subtype}>');
      } else {
        final subTypeDefName = typeDef.subtype!;
        if (isCacheDto) {
          sb.write(
            '<${subTypeDefName.endsWith("CacheDto") ? subTypeDefName : "${subTypeDefName}CacheDto"}>',
          );
        } else {
          sb.write(
              '<${subTypeDefName.endsWith("ApiDto") ? subTypeDefName : "${subTypeDefName}ApiDto"}>');
        }
      }
    }
  }

  String get _classApiDtoName =>
      name.endsWith("ApiDto") ? name : "${name}ApiDto";

  String get _classModelName {
    String substringToRemove = "ApiDto";
    String originalString = _classApiDtoName;
    // Check if the original string ends with the substring to be removed
    if (originalString.endsWith(substringToRemove)) {
      // Calculate the index from which to start removing
      int startIndex = originalString.length - substringToRemove.length;
      // Remove the substring from the end
      return originalString.substring(0, startIndex);
    } else {
      // If the original string doesn't end with the substring to be removed, return the original string
      return originalString;
    }
  }

  String get _classCacheDtoName {
    String substringToRemove = "ApiDto";
    String originalString = _classApiDtoName;
    // Check if the original string ends with the substring to be removed
    if (originalString.endsWith(substringToRemove)) {
      // Calculate the index from which to start removing
      int startIndex = originalString.length - substringToRemove.length;
      // Remove the substring from the end
      originalString = originalString.substring(0, startIndex);
    }
    return "${originalString}CacheDto";
  }

  String _freezedConstructor(String name, bool isModel) {
    StringBuffer sb = StringBuffer();
    sb.write("\t\tconst factory $name(");
    var i = 0;
    var len = fields.keys.length - 1;
    for (var key in fields.keys) {
      if (i == 0) {
        sb.write("{");
      }
      final typeSyntax = fields[key]!;
      final fieldName = fixFieldName(key, typeDef: typeSyntax);
      sb.write("\n\t\t\t\t");
      _addTypeSyntaxString(
        typeSyntax,
        sb,
        isModel: isModel,
        isCacheDto: false,
        jsonKey: key,
      );
      sb.write('? $fieldName,');

      if (i == len) {
        sb.write("\n\t\t}");
      }
      i++;
    }
    sb.write(") = _$name;");
    sb.write("\n\t\tconst $name._();\n\n");
    return sb.toString();
  }

  String _hiveFieldsAndConstructor(String name) {
    StringBuffer sb = StringBuffer();

    var i = 0;
    for (var key in fields.keys) {
      final typeSyntax = fields[key]!;
      final fieldName = fixFieldName(key, typeDef: typeSyntax);
      sb.write("\n\n\t\t@HiveField($i)");
      sb.write("\n\t\t");
      _addTypeSyntaxString(
        typeSyntax,
        sb,
        isModel: false,
        isCacheDto: true,
      );
      sb.write('? $fieldName;');
      i++;
    }
    sb.write("\n\n\t\t@override");
    sb.write("\n\t\t@HiveField($i)");
    sb.write("\n\t\tString? syncTime;");
    i++;
    sb.write("\n\n\t\t@override");
    sb.write("\n\t\t@HiveField($i)");
    sb.write("\n\t\tbool? isSynced;");
    i++;

    sb.write("\n\n\t\t$name(");
    i = 0;
    for (var key in fields.keys) {
      if (i == 0) {
        sb.write("{");
      }
      final typeSyntax = fields[key]!;
      final fieldName = fixFieldName(key, typeDef: typeSyntax);
      sb.write("\n\t\t\t\tthis.$fieldName,");
      i++;
    }
    sb.write("\n\t\t\t\tthis.syncTime,");
    sb.write("\n\t\t\t\tthis.isSynced,");
    sb.write("\n\t\t});");
    return sb.toString();
  }

  String get _toModel {
    StringBuffer sb = StringBuffer();
    sb.write("\t\t@override");
    sb.write("\n\t\t$_classModelName toModel() => $_classModelName(");
    int i = 0;
    final len = fields.keys.length - 1;
    for (var key in fields.keys) {
      final typeSyntax = fields[key]!;
      final fieldName = fixFieldName(key, typeDef: typeSyntax);
      if (typeSyntax.name == "List" && !typeSyntax.isPrimitive) {
        sb.write(
          '\n\t\t\t\t$fieldName: $fieldName?.map((e) => e.toModel()).toList(),',
        );
      } else {
        if (typeSyntax.isPrimitive) {
          sb.write('\n\t\t\t\t$fieldName: $fieldName,');
        } else {
          sb.write('\n\t\t\t\t$fieldName: $fieldName?.toModel(),');
        }
      }
      if (i == len) {
        sb.write("\n\t\t");
      }
      i++;
    }
    sb.write(");");
    return sb.toString();
  }

  String get _toApiDto {
    StringBuffer sb = StringBuffer();
    sb.write("\t\t@override");
    sb.write("\n\t\t$_classApiDtoName toApiDto() => $_classApiDtoName(");
    int i = 0;
    final len = fields.keys.length - 1;
    for (var key in fields.keys) {
      final typeSyntax = fields[key]!;
      final fieldName = fixFieldName(key, typeDef: typeSyntax);
      if (typeSyntax.name == "List" && !typeSyntax.isPrimitive) {
        sb.write(
          '\n\t\t\t\t$fieldName: $fieldName?.map((e) => e.toApiDto()).toList(),',
        );
      } else {
        if (typeSyntax.isPrimitive) {
          sb.write('\n\t\t\t\t$fieldName: $fieldName,');
        } else {
          sb.write('\n\t\t\t\t$fieldName: $fieldName?.toApiDto(),');
        }
      }
      if (i == len) {
        sb.write("\n\t\t");
      }
      i++;
    }
    sb.write(");");
    return sb.toString();
  }

  String get _toCacheDto {
    StringBuffer sb = StringBuffer();
    sb.write("\t\t@override");
    sb.write("\n\t\t$_classCacheDtoName toCacheDto() => $_classCacheDtoName(");
    int i = 0;
    final len = fields.keys.length - 1;
    for (var key in fields.keys) {
      final typeSyntax = fields[key]!;
      final fieldName = fixFieldName(key, typeDef: typeSyntax);
      if (typeSyntax.name == "List" && !typeSyntax.isPrimitive) {
        sb.write(
          '\n\t\t\t\t$fieldName: $fieldName?.map((e) => e.toCacheDto()).toList(),',
        );
      } else {
        if (typeSyntax.isPrimitive) {
          sb.write('\n\t\t\t\t$fieldName: $fieldName,');
        } else {
          sb.write('\n\t\t\t\t$fieldName: $fieldName?.toCacheDto(),');
        }
      }
      if (i == len) {
        sb.write("\n\t\t");
      }
      i++;
    }
    sb.write(");");
    return sb.toString();
  }

  String get apiDto {
    String apiDtoString =
        "@freezed\nclass $_classApiDtoName with _\$$_classApiDtoName implements ApiDto<$_classModelName> {\n";
    apiDtoString += _freezedConstructor(_classApiDtoName, false).toString();
    StringBuffer sb = StringBuffer();
    sb.write(
      "\t\tfactory $_classApiDtoName.fromJson(Map<String, dynamic> json) => _\$${_classApiDtoName}FromJson(json);\n",
    );
    apiDtoString += "${sb.toString()}\n$_toModel\n}\n";
    return apiDtoString;
  }

  String get uiModel {
    String uiModelString =
        "@freezed\nclass $_classModelName with _\$$_classModelName implements UIModel<$_classApiDtoName> {\n";
    uiModelString += _freezedConstructor(_classModelName, true).toString();
    uiModelString += "$_toApiDto\n}\n";
    return uiModelString;
  }

  String get apiCacheDto {
    String apiDtoString =
        "@freezed\nclass $_classApiDtoName with _\$$_classApiDtoName implements ApiCacheDto<$_classCacheDtoName> {\n";
    apiDtoString += _freezedConstructor(_classApiDtoName, false).toString();
    StringBuffer sb = StringBuffer();
    sb.write(
      "\t\tfactory $_classApiDtoName.fromJson(Map<String, dynamic> json) => _\$${_classApiDtoName}FromJson(json);\n",
    );
    apiDtoString += "${sb.toString()}$_toCacheDto\n}\n";
    return apiDtoString;
  }

  String get cacheDto {
    String cacheDtoString =
        "@HiveType(typeId: AppConstants.${_classModelName.toFirstCharLowerCase()}AdapterId)\n";
    cacheDtoString +=
        "class $_classCacheDtoName with HiveObjectMixin implements CacheDto<$_classModelName,$_classApiDtoName> {\n";
    cacheDtoString +=
        "\t\tstatic String boxKey = AppConstants.${_classModelName.toFirstCharLowerCase()}BoxKey;";
    cacheDtoString += _hiveFieldsAndConstructor(_classCacheDtoName).toString();
    cacheDtoString +=
        "\n\n\t\t@override\n\t\tString get number => id.toString(); //Update id to your unique value\n\n$_toModel\n\n$_toApiDto\n}\n";
    return cacheDtoString;
  }

  String get uiCacheModel {
    String uiModelString =
        "@freezed\nclass $_classModelName with _\$$_classModelName implements UICacheModel<$_classCacheDtoName> {\n";
    uiModelString += _freezedConstructor(_classModelName, true).toString();
    uiModelString += "$_toCacheDto\n}\n";
    return uiModelString;
  }

  @override
  String toString() => 'ClassDefinition(name: $name)';
}

class Dependency {
  String name;
  final TypeDefinition typeDef;

  Dependency(this.name, this.typeDef);

  String get className => name.toCamelCase();
}

class TypeDefinition {
  String name;
  String? subtype;
  bool isAmbiguous = false;
  bool _isPrimitive = false;
  bool _isSubTypePrimitive = false;

  TypeDefinition(
    this.name, {
    this.subtype,
    this.isAmbiguous = false,
    Node? astNode,
  }) {
    if (subtype == null) {
      _isPrimitive = isPrimitiveType(name);
      if (name == 'int' && isASTLiteralDouble(astNode)) {
        name = 'double';
      }
    } else {
      _isPrimitive = isPrimitiveType('$name<$subtype>');

      _isSubTypePrimitive = isPrimitiveType(subtype!);
    }
  }

  factory TypeDefinition.fromDynamic(dynamic obj, Node? astNode) {
    bool isAmbiguous = false;
    final type = getTypeName(obj);
    if (type == 'List') {
      List<dynamic> list = obj;
      String elemType;
      if (list.isNotEmpty) {
        elemType = getTypeName(list[0]);
        for (dynamic listVal in list) {
          final typeName = getTypeName(listVal);
          if (elemType != typeName) {
            isAmbiguous = true;
            break;
          }
        }
      } else {
        // when array is empty insert Null just to warn the user
        elemType = "Null";
      }
      return TypeDefinition(type,
          astNode: astNode, subtype: elemType, isAmbiguous: isAmbiguous);
    }
    return TypeDefinition(type, astNode: astNode, isAmbiguous: isAmbiguous);
  }

  bool get isPrimitive => _isPrimitive;
  bool get isSubTypePrimitive => _isSubTypePrimitive;

  bool get isPrimitiveList => _isPrimitive && name == 'List';

  String _buildParseClass(String expression) {
    final properType = subtype ?? name;
    return 'new $properType.fromJson($expression)';
  }

  String _buildToJsonClass(String expression, [bool nullGuard = true]) {
    if (nullGuard) {
      return '$expression!.toJson()';
    }
    return '$expression.toJson()';
  }

  String jsonParseExpression(String key) {
    final jsonKey = "json['$key']";
    final fieldKey = fixFieldName(key, typeDef: this);
    if (isPrimitive) {
      if (name == "List") {
        return "$fieldKey = json['$key'].cast<$subtype>();";
      }
      return "$fieldKey = json['$key'];";
    } else if (name == "List" && subtype == "DateTime") {
      return "$fieldKey = json['$key'].map((v) => DateTime.tryParse(v));";
    } else if (name == "DateTime") {
      return "$fieldKey = DateTime.tryParse(json['$key']);";
    } else if (name == 'List') {
      // list of class
      return "if (json['$key'] != null) {\n\t\t\t$fieldKey = <$subtype>[];\n\t\t\tjson['$key'].forEach((v) { $fieldKey!.add(new $subtype.fromJson(v)); });\n\t\t}";
    } else {
      // class
      return "$fieldKey = json['$key'] != null ? ${_buildParseClass(jsonKey)} : null;";
    }
  }

  String toJsonExpression(String key) {
    final fieldKey = fixFieldName(key, typeDef: this);
    final thisKey = 'this.$fieldKey';
    if (isPrimitive) {
      return "data['$key'] = $thisKey;";
    } else if (name == 'List') {
      // class list
      return """if ($thisKey != null) {
      data['$key'] = $thisKey!.map((v) => ${_buildToJsonClass('v', false)}).toList();
    }""";
    } else {
      // class
      return """if ($thisKey != null) {
      data['$key'] = ${_buildToJsonClass(thisKey)};
    }""";
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TypeDefinition &&
        other.name == name &&
        other.subtype == subtype &&
        other.isAmbiguous == isAmbiguous &&
        other._isPrimitive == _isPrimitive;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        subtype.hashCode ^
        isAmbiguous.hashCode ^
        _isPrimitive.hashCode;
  }
}

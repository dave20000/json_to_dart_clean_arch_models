import 'package:flutter/material.dart';
import 'package:json_to_dart_clean_arch_models/dart_class_generator/helpers.dart';

import '../../dart_class_generator/dart_class_generator.dart';
import '../../dart_class_generator/dart_code.dart';
import '../widgets/converted_classes_card.dart';
import '../widgets/left_side_bar.dart';

class DtoConvertScreen extends StatefulWidget {
  const DtoConvertScreen({super.key});

  @override
  State<DtoConvertScreen> createState() => _DtoConvertScreenState();
}

class _DtoConvertScreenState extends State<DtoConvertScreen> {
  late final TextEditingController _rootClassNameController;
  late final TextEditingController _fieldController;

  late final ScrollController _fieldScrollController;

  late final FocusNode _fieldFocusNode;

  String? convertedApiDtos;
  String? convertedUIModels;

  bool? isFieldFocused = false;

  @override
  void initState() {
    _rootClassNameController = TextEditingController(text: "Sample");
    _fieldController = TextEditingController();

    _fieldScrollController = ScrollController();

    _fieldFocusNode = FocusNode();

    _fieldFocusNode.addListener(_handleFieldFocusChange);
    super.initState();
  }

  @override
  void dispose() {
    _rootClassNameController.dispose();
    _fieldController.dispose();

    _fieldFocusNode.removeListener(_handleFieldFocusChange);
    _fieldFocusNode.dispose();
    super.dispose();
  }

  void _handleFieldFocusChange() {
    setState(() {
      isFieldFocused = _fieldFocusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: const Text("ApiDto and UIModel from JSON"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: LeftSideBar(
                  rootClassNameController: _rootClassNameController,
                  fieldFocusNode: _fieldFocusNode,
                  fieldScrollController: _fieldScrollController,
                  fieldController: _fieldController,
                  convert: () {
                    try {
                      final classGenerator = DartClassGenerator(
                        _rootClassNameController.text.capitalize(),
                      );
                      DartCode apiDtosDartCode = classGenerator
                          .generateApiDtoClasses(_fieldController.text);
                      DartCode uiModelsDartCode = classGenerator
                          .generateUIModelClasses(_fieldController.text);
                      // print(dartCode.code);
                      setState(() {
                        convertedApiDtos = apiDtosDartCode.code;
                        convertedUIModels = uiModelsDartCode.code;
                      });
                    } on FormatException catch (ex) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ex.message),
                        ),
                      );
                    } on RangeError catch (ex) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ex.message),
                        ),
                      );
                    } catch (ex) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ex.toString()),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ConvertedClassesCard(
                  title: "Api Dto",
                  convertedModels: convertedApiDtos,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ConvertedClassesCard(
                  title: "UI Model",
                  convertedModels: convertedUIModels,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

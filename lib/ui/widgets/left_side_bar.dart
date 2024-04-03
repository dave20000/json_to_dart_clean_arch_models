import 'package:flutter/material.dart';

class LeftSideBar extends StatelessWidget {
  const LeftSideBar({
    super.key,
    required TextEditingController rootClassNameController,
    required FocusNode fieldFocusNode,
    required ScrollController fieldScrollController,
    required TextEditingController fieldController,
    required VoidCallback convert,
  })  : _rootClassNameController = rootClassNameController,
        _fieldFocusNode = fieldFocusNode,
        _fieldScrollController = fieldScrollController,
        _fieldController = fieldController,
        _convert = convert;

  final TextEditingController _rootClassNameController;
  final FocusNode _fieldFocusNode;
  final ScrollController _fieldScrollController;
  final TextEditingController _fieldController;
  final VoidCallback _convert;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Name",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        TextField(
          maxLines: 1,
          controller: _rootClassNameController,
          // cursorColor: Colors.black,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            // fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            // enabledBorder: InputBorder.none,
            // focusedBorder: InputBorder.none,
            // errorBorder: InputBorder.none,
            // disabledBorder: InputBorder.none,
            // focusedErrorBorder: InputBorder.none,
          ),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              border: Border.all(
                width: _fieldFocusNode.hasFocus ? 2 : 1,
                color: _fieldFocusNode.hasFocus
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(12),
              // color: Theme.of(context).colorScheme.onSurface,
            ),
            child: TextField(
              maxLines: null,
              controller: _fieldController,
              scrollController: _fieldScrollController,
              focusNode: _fieldFocusNode,
              // cursorColor: Colors.black,
              decoration: const InputDecoration(
                // fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: 20,
                horizontal: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _convert,
            child: Text(
              "Convert",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ],
    );
  }
}

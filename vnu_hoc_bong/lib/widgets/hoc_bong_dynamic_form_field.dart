import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:vnu_core/common/app_colors.dart';
import 'package:vnu_core/common/app_text_styles.dart';

import '../models/hoc_bong_models.dart';

class HocBongDynamicFormField extends StatelessWidget {
  final HocBongFormFieldModel field;
  final dynamic value;
  final String? pendingFilePath;
  final ValueChanged<dynamic> onChanged;
  final ValueChanged<File> onFileSelected;

  const HocBongDynamicFormField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    required this.onFileSelected,
    this.pendingFilePath,
  });

  @override
  Widget build(BuildContext context) {
    switch (field.kieuDuLieu) {
      case 'TEXTAREA':
        return _TextInput(
          field: field,
          hint: field.goiY,
          value: value?.toString(),
          maxLines: 4,
          onChanged: onChanged,
        );
      case 'NUMBER':
        return _TextInput(
          field: field,
          hint: field.goiY,
          value: value?.toString(),
          keyboardType: TextInputType.number,
          onChanged: onChanged,
        );
      case 'DATE':
        return _DateInput(field: field, value: value?.toString(), onChanged: onChanged);
      case 'SELECT':
        if (field.options.isEmpty) {
          return _TextInput(
            field: field,
            hint: field.goiY ?? 'Nhập ${field.displayLabel.toLowerCase()}',
            value: value?.toString(),
            onChanged: onChanged,
          );
        }
        return _SelectInput(field: field, value: value?.toString(), options: field.options, onChanged: onChanged);
      case 'BOOLEAN':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HocBongFieldLabel(field: field),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                field.goiY ?? 'Có / Không',
                style: TextStyles.regular.copyWith(fontSize: 14, color: Colors.black87),
              ),
              value: value == true,
              activeColor: AppColors.greenAccent,
              checkColor: Colors.white,
              controlAffinity: ListTileControlAffinity.leading,
              side: BorderSide(
                color: value == true ? AppColors.greenAccent : Colors.grey.shade400,
                width: 1.5,
              ),
              onChanged: onChanged,
            ),
          ],
        );
      case 'FILE':
        return _FileInput(field: field, hint: field.goiY, pendingFilePath: pendingFilePath, onFileSelected: onFileSelected);
      case 'TEXT':
      default:
        return _TextInput(field: field, hint: field.goiY, value: value?.toString(), onChanged: onChanged);
    }
  }
}

/// Tiêu đề trường luôn hiển thị (không dùng `labelText` của Material — tránh chỉ thấy dấu *).
class HocBongFieldLabel extends StatelessWidget {
  final HocBongFormFieldModel field;

  const HocBongFieldLabel({super.key, required this.field});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              field.displayLabel,
              style: TextStyles.semiBold.copyWith(fontSize: 14, color: Colors.black87),
            ),
          ),
          if (field.batBuoc)
            Text(
              ' *',
              style: TextStyles.bold.copyWith(fontSize: 14, color: AppColors.error),
            ),
          if (field.yeuCauCongChung) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.notifyOrangeBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Công chứng',
                style: TextStyles.medium.copyWith(fontSize: 10, color: AppColors.notifyOrange),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TextInput extends StatefulWidget {
  final HocBongFormFieldModel field;
  final String? hint;
  final String? value;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String> onChanged;

  const _TextInput({
    required this.field,
    this.hint,
    this.value,
    this.maxLines = 1,
    this.keyboardType,
    required this.onChanged,
  });

  @override
  State<_TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<_TextInput> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.value ?? '');
  }

  @override
  void didUpdateWidget(covariant _TextInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.value ?? '') != controller.text) {
      controller.text = widget.value ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = (widget.value != null && widget.value!.isNotEmpty) || controller.text.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HocBongFieldLabel(field: widget.field),
          TextFormField(
            controller: controller,
            maxLines: widget.maxLines,
            keyboardType: widget.keyboardType,
            style: TextStyles.regular.copyWith(fontSize: 14, color: Colors.black87),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyles.regular.copyWith(color: Colors.grey.shade500),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: hasValue ? AppColors.greenAccent : Colors.grey.shade300,
                  width: hasValue ? 1.5 : 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.greenAccent, width: 1.5),
              ),
            ),
            onChanged: widget.onChanged,
          ),
        ],
      ),
    );
  }
}

class _SelectInput extends StatelessWidget {
  final HocBongFormFieldModel field;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _SelectInput({
    required this.field,
    this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HocBongFieldLabel(field: field),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: options.contains(value) ? value : null,
            items: options.map((e) => DropdownMenuItem(
              value: e,
              child: Text(
                e,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            )).toList(),
            hint: Text(
              'Chọn ${field.displayLabel.toLowerCase()}',
              style: TextStyles.regular.copyWith(color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: hasValue ? AppColors.greenAccent : Colors.grey.shade300,
                  width: hasValue ? 1.5 : 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.greenAccent, width: 1.5),
              ),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _DateInput extends StatelessWidget {
  final HocBongFormFieldModel field;
  final String? value;
  final ValueChanged<String> onChanged;

  const _DateInput({required this.field, this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HocBongFieldLabel(field: field),
          InkWell(
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.tryParse(value ?? '') ?? now,
                firstDate: DateTime(now.year - 10),
                lastDate: DateTime(now.year + 10),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.greenAccent,
                        onPrimary: Colors.white,
                        onSurface: Colors.black87,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.greenAccent,
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) onChanged(picked.toIso8601String());
            },
            child: InputDecorator(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: value != null ? AppColors.greenAccent : Colors.grey.shade300, width: value != null ? 1.5 : 1),
                ),
              ),
              child: Text(
                value?.split('T').first ?? 'Chọn ngày',
                style: TextStyles.regular.copyWith(fontSize: 14, color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FileInput extends StatelessWidget {
  final HocBongFormFieldModel field;
  final String? hint;
  final String? pendingFilePath;
  final ValueChanged<File> onFileSelected;

  const _FileInput({
    required this.field,
    this.hint,
    this.pendingFilePath,
    required this.onFileSelected,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = pendingFilePath?.split(Platform.pathSeparator).last;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: fileName != null ? AppColors.greenAccent : Colors.grey.shade300, width: fileName != null ? 1.5 : 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HocBongFieldLabel(field: field),
          if (hint != null) ...[
            Text(hint!, style: TextStyles.regular.copyWith(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  fileName ?? 'Chưa chọn file (PDF)',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.regular.copyWith(fontSize: 13, color: Colors.grey.shade700),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: const BorderSide(color: AppColors.greenAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final result = await FilePicker.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf'],
                    allowMultiple: false,
                  );
                  final path = result?.files.single.path;
                  if (path != null) onFileSelected(File(path));
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.attach_file, size: 16, color: AppColors.greenAccent),
                    SizedBox(width: 4),
                    Text(
                      'Chọn file',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

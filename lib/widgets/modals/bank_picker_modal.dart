import 'package:flutter/material.dart';

import '../../core/constants/venezuelan_banks.dart';
import '../../core/theme/app_colors.dart';

Future<String?> showBankPickerModal(
  BuildContext context, {
  String? selectedBank,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _BankPickerSheet(selectedBank: selectedBank),
  );
}

class _BankPickerSheet extends StatefulWidget {
  const _BankPickerSheet({this.selectedBank});

  final String? selectedBank;

  @override
  State<_BankPickerSheet> createState() => _BankPickerSheetState();
}

class _BankPickerSheetState extends State<_BankPickerSheet> {
  final _searchController = TextEditingController();
  late List<String> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = VenezuelanBanks.all;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() => _filtered = VenezuelanBanks.search(value));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Seleccionar banco',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (widget.selectedBank != null &&
                      VenezuelanBanks.all.length > 1)
                    TextButton(
                      onPressed: () => Navigator.pop(context, ''),
                      child: const Text('Quitar'),
                    ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            if (VenezuelanBanks.all.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: 'Buscar banco…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _onSearch('');
                            },
                            icon: const Icon(Icons.clear),
                          ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No se encontró ningún banco',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final bank = _filtered[index];
                        final selected = bank == widget.selectedBank;
                        return ListTile(
                          onTap: () => Navigator.pop(context, bank),
                          leading: CircleAvatar(
                            backgroundColor: selected
                                ? AppColors.ink
                                : AppColors.softFill,
                            child: Icon(
                              Icons.account_balance_outlined,
                              size: 18,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                          title: Text(
                            bank,
                            style: TextStyle(
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          trailing: selected
                              ? const Icon(Icons.check_circle, color: AppColors.green)
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

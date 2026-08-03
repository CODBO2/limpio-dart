import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../models/fuente.dart';
import '../providers/fuentes_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/fuente_card.dart';
import '../widgets/modals/edit_fuente_modal.dart';

class IngresosFijosScreen extends ConsumerStatefulWidget {
  const IngresosFijosScreen({super.key});

  @override
  ConsumerState<IngresosFijosScreen> createState() => _IngresosFijosScreenState();
}

class _IngresosFijosScreenState extends ConsumerState<IngresosFijosScreen> {
  final _nombreController = TextEditingController();
  final _montoController = TextEditingController();
  final _diaController = TextEditingController();
  String _moneda = 'USD';

  @override
  void dispose() {
    _nombreController.dispose();
    _montoController.dispose();
    _diaController.dispose();
    super.dispose();
  }

  Future<void> _handleAdd() async {
    final name = _nombreController.text.trim();
    final amount = _montoController.text.trim();
    final day = int.tryParse(_diaController.text.trim()) ?? 0;
    if (name.isEmpty || amount.isEmpty || day < 1 || day > 31) return;

    await ref.read(fuentesProvider.notifier).add(
          name: name,
          amount: amount,
          currency: _moneda,
          day: day,
        );

    _nombreController.clear();
    _montoController.clear();
    _diaController.clear();
  }

  void _openEdit(Fuente fuente) {
    showEditFuenteModal(
      context,
      fuente: fuente,
      onSave: (updated) => ref.read(fuentesProvider.notifier).update(updated),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fuentes = ref.watch(fuentesProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 120),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAF9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF5F5F4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.bar_chart, color: AppColors.greenDark),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INGRESOS FIJOS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.greenDark,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'Mis fuentes de ingreso',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Gestiona tus entradas mensuales recurrentes. Añade fuentes abajo y aparecerán en Billetera.',
                style: TextStyle(color: Color(0xFF57534E), height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'AÑADIR FUENTE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(hintText: 'Nombre (ej. Salario)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _montoController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(hintText: 'Monto'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => setState(() => _moneda = _moneda == 'USD' ? 'VES' : 'USD'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_moneda == 'USD' ? '\$' : 'VES'),
                        const Icon(Icons.keyboard_arrow_down),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _diaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Día de cobro (1-31)'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _handleAdd,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Añadir Ingreso',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'MIS FUENTES',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
        const SizedBox(height: 14),
        if (fuentes.isEmpty)
          const EmptyState(
            variant: EmptyStateVariant.fuentes,
            title: 'Aquí aparecerán tus fuentes de ingreso fijo',
            tutorial:
                'Completa el formulario de arriba (nombre, monto, día de cobro) y pulsa «Añadir Ingreso» para crear una fuente. Así podrás tener ingresos recurrentes visibles en Billetera.',
          )
        else
          ...fuentes.map(
            (f) => FuenteCard(
              item: f,
              onPress: _openEdit,
              onDelete: (item) => ref.read(fuentesProvider.notifier).remove(item.id),
            ),
          ),
      ],
    );
  }
}

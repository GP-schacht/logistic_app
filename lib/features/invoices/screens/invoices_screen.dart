import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/invoices.dart';
import '../providers/invoice_provider.dart';
import '../../../shared/widgets/bottom_navegation.dart';

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Filtros ──────────────────────────────────────────────
  Future<void> _pickDate(bool isFrom) async {
    final filter  = ref.read(invoiceFilterProvider);
    final initial = isFrom
        ? (filter.fromDate ?? DateTime.now())
        : (filter.toDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;

    ref.read(invoiceFilterProvider.notifier).update((s) => isFrom
        ? s.copyWith(fromDate: picked)
        : s.copyWith(toDate: picked));
  }

  void _clearFilters() {
    _searchCtrl.clear();
    ref.read(invoiceFilterProvider.notifier).state = const InvoiceFilter();
  }

  bool get _hasFilters {
    final f = ref.read(invoiceFilterProvider);
    return f.query.isNotEmpty ||
        f.fromDate != null ||
        f.toDate != null ||
        f.sort != InvoiceSort.newest;
  }

  @override
  Widget build(BuildContext context) {
    final filter   = ref.watch(invoiceFilterProvider);
    final invoices = ref.watch(filteredInvoicesProvider);
    final loading  = ref.watch(invoicesProvider).isLoading;

    return MainScaffold(
      title: 'Facturas',
      child: Column(
        children: [
          _SearchBar(
            controller: _searchCtrl,
            onChanged: (q) => ref
                .read(invoiceFilterProvider.notifier)
                .update((s) => s.copyWith(query: q)),
          ),
          _FilterRow(
            filter: filter,
            hasFilters: _hasFilters,
            onPickFrom:  () => _pickDate(true),
            onPickTo:    () => _pickDate(false),
            onSort: (sort) => ref
                .read(invoiceFilterProvider.notifier)
                .update((s) => s.copyWith(sort: sort)),
            onClear: _clearFilters,
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : invoices.isEmpty
                    ? const _EmptyState()
                    : RefreshIndicator(
                        onRefresh: () async =>
                            ref.invalidate(invoicesProvider),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: invoices.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) =>
                              _InvoiceCard(invoice: invoices[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Barra de búsqueda ────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Buscar por Nº factura o cliente…',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }
}

// ── Fila de filtros ──────────────────────────────────────

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.filter,
    required this.hasFilters,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onSort,
    required this.onClear,
  });
  final InvoiceFilter filter;
  final bool hasFilters;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final void Function(InvoiceSort) onSort;
  final VoidCallback onClear;

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          // Desde
          _FilterChip(
            label: filter.fromDate != null
                ? 'Desde: ${_fmt(filter.fromDate!)}'
                : 'Desde',
            icon: Icons.calendar_today_outlined,
            active: filter.fromDate != null,
            onTap: onPickFrom,
          ),
          const SizedBox(width: 8),
          // Hasta
          _FilterChip(
            label: filter.toDate != null
                ? 'Hasta: ${_fmt(filter.toDate!)}'
                : 'Hasta',
            icon: Icons.event_outlined,
            active: filter.toDate != null,
            onTap: onPickTo,
          ),
          const SizedBox(width: 8),
          // Orden
          _FilterChip(
            label: filter.sort == InvoiceSort.newest
                ? 'Más reciente'
                : 'Más antiguo',
            icon: Icons.sort,
            active: filter.sort == InvoiceSort.oldest,
            onTap: () => onSort(filter.sort == InvoiceSort.newest
                ? InvoiceSort.oldest
                : InvoiceSort.newest),
          ),
          if (hasFilters) ...[
            const SizedBox(width: 8),
            ActionChip(
              label: const Text('Limpiar'),
              avatar: const Icon(Icons.close, size: 14),
              onPressed: onClear,
              backgroundColor: Colors.red.shade50,
              labelStyle: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });
  final String   label;
  final IconData icon;
  final bool     active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.blue : Colors.grey.shade600;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? Colors.blue.withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? Colors.blue : Colors.grey.shade300,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.normal)),
        ]),
      ),
    );
  }
}

// ── Tarjeta de factura ───────────────────────────────────

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice});
  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = switch (invoice.status) {
      'pagado'    => ('Pagado',    Colors.green),
      'cancelado' => ('Cancelado', Colors.red),
      _           => ('Pendiente', Colors.orange),
    };

    return Card(
      elevation: 1,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/invoices/${invoice.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                Expanded(
                  child: Text(
                    invoice.invoiceNumber,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                _StatusBadge(label: statusLabel, color: statusColor),
              ]),
              const SizedBox(height: 6),

              // Cliente
              if (invoice.clientName != null) ...[
                Row(children: [
                  Icon(Icons.business_outlined,
                      size: 13, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(invoice.clientName!,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade700)),
                ]),
                const SizedBox(height: 4),
              ],

              // Ruta
              if (invoice.origin != null && invoice.destination != null)
                Row(children: [
                  Icon(Icons.route_outlined,
                      size: 13, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${invoice.origin} → ${invoice.destination}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),

              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Footer
              Row(children: [
                Icon(Icons.calendar_today_outlined,
                    size: 12, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(_fmtDate(invoice.generatedAt),
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
                const Spacer(),
                Text(
                  '\$${invoice.amount.toStringAsFixed(2)} ${invoice.currency}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.receipt_long_outlined,
          size: 64, color: Colors.grey.shade400),
      const SizedBox(height: 16),
      Text('No hay facturas',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
      const SizedBox(height: 4),
      Text('Se generan automáticamente al iniciar un viaje',
          style: TextStyle(
              color: Colors.grey.shade400, fontSize: 12)),
    ]),
  );
}
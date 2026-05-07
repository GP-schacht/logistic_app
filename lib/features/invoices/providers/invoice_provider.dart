import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../models/invoices.dart';

// ── Enum de orden ────────────────────────────────────────
enum InvoiceSort { newest, oldest }

// ── Estado de filtros ────────────────────────────────────
class InvoiceFilter {
  final String query;           // número de factura, cliente
  final DateTime? fromDate;
  final DateTime? toDate;
  final InvoiceSort sort;

  const InvoiceFilter({
    this.query = '',
    this.fromDate,
    this.toDate,
    this.sort = InvoiceSort.newest,
  });

  InvoiceFilter copyWith({
    String? query,
    DateTime? fromDate,
    DateTime? toDate,
    InvoiceSort? sort,
    bool clearFromDate = false,
    bool clearToDate = false,
  }) => InvoiceFilter(
    query:    query    ?? this.query,
    fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
    toDate:   clearToDate   ? null : (toDate   ?? this.toDate),
    sort:     sort     ?? this.sort,
  );
}

// ── Provider del filtro (StateProvider) ──────────────────
final invoiceFilterProvider =
    StateProvider<InvoiceFilter>((_) => const InvoiceFilter());

// ── Lista de facturas (todas) ─────────────────────────────
final invoicesProvider = FutureProvider<List<Invoice>>((ref) async {
  final rows = await supabase
      .from('invoices')
      .select('''
        *,
        trips(
          origin, destination,
          trucks(plate),
          containers(container_number),
          drivers(profiles(full_name))
        )
      ''')
      .order('generated_at', ascending: false);

  return rows.map((r) => Invoice.fromMap(r)).toList();
});

// ── Lista filtrada (derivada) ─────────────────────────────
final filteredInvoicesProvider = Provider<List<Invoice>>((ref) {
  final invoicesAsync = ref.watch(invoicesProvider);
  final filter        = ref.watch(invoiceFilterProvider);

  return invoicesAsync.when(
    loading: () => [],
    error:   (_, __) => [],
    data: (invoices) {
      var list = invoices.toList();

      // Filtro por texto (número de factura o cliente)
      final q = filter.query.trim().toLowerCase();
      if (q.isNotEmpty) {
        list = list.where((inv) {
          final number = inv.invoiceNumber.toLowerCase();
          final client = (inv.clientName ?? '').toLowerCase();
          return number.contains(q) || client.contains(q);
        }).toList();
      }

      // Filtro por fecha
      if (filter.fromDate != null) {
        list = list.where(
          (inv) => inv.generatedAt.isAfter(
            filter.fromDate!.subtract(const Duration(seconds: 1))),
        ).toList();
      }
      if (filter.toDate != null) {
        final endOfDay = DateTime(
          filter.toDate!.year,
          filter.toDate!.month,
          filter.toDate!.day,
          23, 59, 59,
        );
        list = list.where(
          (inv) => inv.generatedAt.isBefore(endOfDay),
        ).toList();
      }

      // Orden
      list.sort((a, b) => filter.sort == InvoiceSort.newest
          ? b.generatedAt.compareTo(a.generatedAt)
          : a.generatedAt.compareTo(b.generatedAt));

      return list;
    },
  );
});

// ── Clientes únicos (para sugerencias) ───────────────────
final uniqueClientsProvider = Provider<List<String>>((ref) {
  final invoicesAsync = ref.watch(invoicesProvider);
  return invoicesAsync.when(
    loading: () => [],
    error:   (_, __) => [],
    data: (invoices) => invoices
        .map((i) => i.clientName ?? '')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort(),
  );
});

// ── Una factura por id ───────────────────────────────────
final invoiceByIdProvider =
    FutureProvider.family<Invoice?, String>((ref, id) async {
  final row = await supabase
      .from('invoices')
      .select('''
        *,
        trips(
          origin, destination,
          trucks(plate),
          containers(container_number),
          drivers(profiles(full_name))
        )
      ''')
      .eq('id', id)
      .maybeSingle();
  return row == null ? null : Invoice.fromMap(row);
});

// ── Repositorio ──────────────────────────────────────────
class InvoicesRepository {
  /// Genera factura automáticamente cuando un trip pasa a 'en_curso'.
  /// Llamar desde TripDetailScreen al avanzar estado.
  Future<Invoice?> generateForTrip(String tripId) async {
    // Verificar que no exista ya
    final existing = await supabase
        .from('invoices')
        .select('id')
        .eq('trip_id', tripId)
        .maybeSingle();
    if (existing != null) return null;

    // Obtener datos del trip
    final tripRow = await supabase
        .from('trips')
        .select('''
          origin, destination, client_name, client_id,
          trucks(plate),
          containers(container_number),
          drivers(profiles(full_name))
        ''')
        .eq('id', tripId)
        .single();

    final now    = DateTime.now();
    final number = _buildInvoiceNumber(now);

    final inserted = await supabase.from('invoices').insert({
      'trip_id':        tripId,
      'invoice_number': number,
      'client_name':    tripRow['client_name'],
      'client_id':      tripRow['client_id'],
      'amount':         0.0,   // Se actualiza manualmente o por regla de negocio
      'currency':       'USD',
      'status':         'pendiente',
      'generated_at':   now.toIso8601String(),
    }).select().single();

    return Invoice.fromMap({...inserted, 'trips': tripRow});
  }

  Future<void> markAsPaid(String invoiceId) async {
    await supabase.from('invoices').update({
      'status':   'pagado',
      'paid_at':  DateTime.now().toIso8601String(),
    }).eq('id', invoiceId);
  }

  Future<void> cancel(String invoiceId) async {
    await supabase.from('invoices').update({
      'status': 'cancelado',
    }).eq('id', invoiceId);
  }

  Future<void> updateAmount(String invoiceId, double amount) async {
    await supabase.from('invoices').update({
      'amount': amount,
    }).eq('id', invoiceId);
  }

  String _buildInvoiceNumber(DateTime dt) {
    final year  = dt.year.toString();
    final month = dt.month.toString().padLeft(2, '0');
    final rand  = (dt.millisecondsSinceEpoch % 100000)
        .toString().padLeft(5, '0');
    return 'INV-$year$month-$rand';
  }
}

final invoicesRepoProvider = Provider((_) => InvoicesRepository());
class Invoice {
  final String id;
  final String invoiceNumber;
  final String tripId;
  final String? clientName;
  final String? clientId;
  final double amount;
  final String currency;
  final String status; // 'pendiente' | 'pagado' | 'cancelado'
  final DateTime generatedAt;
  final DateTime? paidAt;

  // Datos enriquecidos del viaje
  final String? origin;
  final String? destination;
  final String? truckPlate;
  final String? driverName;
  final String? containerNumber;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.tripId,
    this.clientName,
    this.clientId,
    required this.amount,
    this.currency = 'USD',
    required this.status,
    required this.generatedAt,
    this.paidAt,
    this.origin,
    this.destination,
    this.truckPlate,
    this.driverName,
    this.containerNumber,
  });

  factory Invoice.fromMap(Map<String, dynamic> m) => Invoice(
    id:              m['id'] as String,
    invoiceNumber:   m['invoice_number'] as String,
    tripId:          m['trip_id'] as String,
    clientName:      m['client_name'] as String?,
    clientId:        m['client_id'] as String?,
    amount:          (m['amount'] as num?)?.toDouble() ?? 0.0,
    currency:        m['currency'] as String? ?? 'USD',
    status:          m['status'] as String? ?? 'pendiente',
    generatedAt:     DateTime.parse(m['generated_at'] as String),
    paidAt:          m['paid_at'] != null
                         ? DateTime.parse(m['paid_at'] as String) : null,
    origin:          m['trips']?['origin'] as String?,
    destination:     m['trips']?['destination'] as String?,
    truckPlate:      m['trips']?['trucks']?['plate'] as String?,
    driverName:      m['trips']?['drivers']?['profiles']?['full_name'] as String?,
    containerNumber: m['trips']?['containers']?['container_number'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'trip_id':        tripId,
    'client_name':    clientName,
    'client_id':      clientId,
    'amount':         amount,
    'currency':       currency,
    'status':         status,
    'generated_at':   generatedAt.toIso8601String(),
  };
}
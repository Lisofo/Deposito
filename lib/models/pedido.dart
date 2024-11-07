class Pedido{
  late int pedidoId;
  late String numPedido;
  late String descripcion;
  late DateTime fechaPedido;
  late DateTime fechaEntrega;
  late DateTime fechaVencimiento;
  late String codTransaccion;
  late int transaccionId;
  late String transaccion;
  late int monedaId;
  late String codMoneda;
  late String signo;
  late double montoTotal;
  late double descuento;
  late String condiciones;

  Pedido({
    required this.pedidoId,
    required this.numPedido,
    required this.descripcion,
    required this.fechaPedido,
    required this.fechaEntrega,
    required this.fechaVencimiento,
    required this.codTransaccion,
    required this.transaccionId,
    required this.transaccion,
    required this.monedaId,
    required this.codMoneda,
    required this.signo,
    required this.montoTotal,
    required this.descuento,
    required this.condiciones,
  });

  Pedido.empty(){
    pedidoId = 0;
    numPedido = '';
    descripcion = '';
    fechaPedido = DateTime.now();
    fechaEntrega = DateTime.now();
    fechaVencimiento = DateTime.now();
    codTransaccion = '';
    transaccionId = 0;
    transaccion = '';
    monedaId = 0;
    codMoneda = '';
    signo = '';
    montoTotal = 0.0;
    descuento = 0.0;
    condiciones = '';
  }
}
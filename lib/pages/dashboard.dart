import 'package:deposito/config/router/router.dart';
import 'package:deposito/widgets/indicator.dart';
import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int totalDePedidos = 0;
  int pedidosPendientes = 20;
  int pedidosCompletados = 50;
  int pedidosEnEspera = 10;

  int numeroGuardado = 0;
  String? selectedValue;
  double percentCompletados = 0;
  double percentPendientes = 0;
  double percentEnEspera = 0;

  // Estado para controlar el tipo de gráfica
  ChartType _chartType = ChartType.pie;
  List<Pedido> pedidos = [];

  @override
  void initState() {
    super.initState();
    // Aquí puedes inicializar la lista de pedidos con datos de prueba o vacía
    pedidos = [
      Pedido(cantidad: 50, estado: 'Completado'),
      Pedido(cantidad: 20, estado: 'Pendiente'),
      Pedido(cantidad: 10, estado: 'En Espera'),
    ];
    actualizarTotales();
  }

  void actualizarTotales() {
    totalDePedidos = pedidos.fold(0, (sum, pedido) => sum + pedido.cantidad);
    percentCompletados = calcularPorcentaje('Completado');
    percentPendientes = calcularPorcentaje('Pendiente');
    percentEnEspera = calcularPorcentaje('En Espera');
  }

  double calcularPorcentaje(String estado) {
    int total = pedidos.where((pedido) => pedido.estado == estado).fold(0, (sum, pedido) => sum + pedido.cantidad);
    return double.parse((100 * total / totalDePedidos).toStringAsFixed(1));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    var alto = MediaQuery.of(context).size.height;
    var ancho = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton.filledTonal(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(colors.primary),
            ),
            onPressed: () async {
              appRouter.pop();
            },
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(
            'Dashboard',
            style: TextStyle(fontSize: 24, color: colors.onPrimary),
          ),
          elevation: 0,
          backgroundColor: colors.primary,
          iconTheme: IconThemeData(color: colors.onPrimary),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '$totalDePedidos Pedidos totales',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const Text(
                    'Estado de los Pedidos del dia:',
                    style: TextStyle(fontSize: 20),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    height: alto > ancho ? 400 : 600,
                    child: Chart(
                      rebuild: true, // Permitir que la gráfica se reconstruya
                      data: getChartData(),
                      variables: {
                        'genre': Variable(
                          accessor: (Map map) => map['status'] as String,
                        ),
                        'sold': Variable(
                          accessor: (Map map) => map['value'] as num,
                        ),
                      },
                      transforms: [
                        Proportion(
                          variable: 'sold',
                          as: 'percent',
                        ),
                      ],
                      marks: _getMarksForChartType(),
                      coord: _getCoordForChartType(),
                    ),
                  ),
                  Indicator(
                    color: Colors.blue,
                    text: '${calcularTotal('Completado')} Pedidos Completados',
                    isSquare: true,
                  ),
                  const SizedBox(height: 4),
                  Indicator(
                    color: Colors.yellow,
                    text: '${calcularTotal('Pendiente')} Pedidos Pendientes',
                    isSquare: true,
                  ),
                  const SizedBox(height: 4),
                  Indicator(
                    color: Colors.purple,
                    text: '${calcularTotal('En Espera')} Pedidos en espera de revision',
                    isSquare: true,
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return StatefulBuilder(
                            builder: (context, setStateBd) => AlertDialog (
                              actionsAlignment: MainAxisAlignment.spaceEvenly,
                              surfaceTintColor: Colors.white,
                              title: const Text('Confirmación'),
                              content: const Text('Seleccione tipo de pedido y cantidad a agregar'),
                              actions: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    DropdownButton<String>(
                                      hint: const Text('Tipo de pedido'),
                                      value: selectedValue,
                                      onChanged: (String? newValue) {
                                        setStateBd(() {
                                          selectedValue = newValue;
                                        });
                                      },
                                      items: <String>['Completado', 'Pendiente', 'En Espera'].map<DropdownMenuItem<String>>((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                    ),
                                    SizedBox(
                                      width: 160,
                                      child: TextField(
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Ingrese cantidad',
                                          border: OutlineInputBorder(),
                                        ),
                                        onChanged: (value) {
                                          final intValue = int.tryParse(value);
                                          if (intValue != null) {
                                            setStateBd(() {
                                              numeroGuardado = intValue;
                                            });
                                          }
                                        },
                                      ),
                                    )
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          pedidos.add(Pedido(cantidad: numeroGuardado, estado: selectedValue!));
                                          actualizarTotales();
                                        });
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('Confirmar'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    child: const Text(
                      'Agregue Pedidos',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Fila de botones para cambiar entre gráficas
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildChartTypeButton(ChartType.pie, 'Pie'),
                        _buildChartTypeButton(ChartType.bar, 'Barras'),
                        _buildChartTypeButton(ChartType.line, 'Líneas'),
                        _buildChartTypeButton(ChartType.area, 'Áreas'),
                        _buildChartTypeButton(ChartType.radar, 'Radar'),
                        _buildChartTypeButton(ChartType.scatter, 'Dispersión'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int calcularTotal(String estado) {
    return pedidos.where((pedido) => pedido.estado == estado).fold(0, (sum, pedido) => sum + pedido.cantidad);
  }

  // Método para construir botones de tipo de gráfica
  Widget _buildChartTypeButton(ChartType type, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _chartType = type;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _chartType == type ? Colors.blue : Colors.grey,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  // Método para obtener las marcas según el tipo de gráfica
  List<Mark> _getMarksForChartType() {
    switch (_chartType) {
      case ChartType.pie:
        return [
          IntervalMark(
            position: Varset('percent') / Varset('genre'),
            label: LabelEncode(
              encoder: (tuple) => Label(
                '${tuple['sold'].toStringAsFixed(1)}%',
                LabelStyle(
                  textStyle: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  align: Alignment.center,
                ),
              ),
            ),
            color: ColorEncode(
              variable: 'genre',
              values: [Colors.blue, Colors.yellow, Colors.purple],
            ),
            modifiers: [StackModifier()],
            transition: Transition(duration: const Duration(milliseconds: 300)),
          ),
        ];
      case ChartType.bar:
        return [
          IntervalMark(
            position: Varset('genre') * Varset('sold'),
            color: ColorEncode(
              variable: 'genre',
              values: [Colors.blue, Colors.yellow, Colors.purple],
            ),
          ),
        ];
      case ChartType.line:
        return [
          LineMark(
            position: Varset('genre') * Varset('sold'),
            color: ColorEncode(
              variable: 'genre',
              values: [Colors.blue, Colors.yellow, Colors.purple],
            ),
          ),
        ];
      case ChartType.area:
        return [
          AreaMark(
            position: Varset('genre') * Varset('sold'),
            color: ColorEncode(
              variable: 'genre',
              values: [Colors.blue, Colors.yellow, Colors.purple],
            ),
          ),
        ];
      case ChartType.radar:
        return [
          IntervalMark(
            
            position: Varset('genre') * Varset('sold'),
            color: ColorEncode(
              variable: 'genre',
              values: [Colors.blue, Colors.yellow, Colors.purple],
            ),
          ),
        ];
      case ChartType.scatter:
        return [
          PointMark(
            position: Varset('genre') * Varset('sold'),
            color: ColorEncode(
              variable: 'genre',
              values: [Colors.blue, Colors.yellow, Colors.purple],
            ),
          ),
        ];
    }
  }

  // Método para obtener el tipo de coordenadas según el tipo de gráfica
  Coord _getCoordForChartType() {
    switch (_chartType) {
      case ChartType.pie:
        return PolarCoord(transposed: true, dimCount: 1);
      case ChartType.radar:
        return PolarCoord();
      default:
        return RectCoord();
    }
  }

  List<Map<String, dynamic>> getChartData() {
    return [
      {'status': 'Completados', 'value': percentCompletados},
      {'status': 'Pendientes', 'value': percentPendientes},
      {'status': 'En Espera', 'value': percentEnEspera},
    ];
  }

  void actualizarPorcentajes() {
    percentCompletados = double.parse((100 * pedidosCompletados / totalDePedidos).toStringAsFixed(1));
    percentPendientes = double.parse((100 * pedidosPendientes / totalDePedidos).toStringAsFixed(1));
    percentEnEspera = double.parse((100 * pedidosEnEspera / totalDePedidos).toStringAsFixed(1));
  }
}

enum ChartType {
  pie,
  bar,
  line,
  area,
  radar,
  scatter,
}

class Pedido {
  final int cantidad;
  final String estado;

  Pedido({required this.cantidad, required this.estado});
}
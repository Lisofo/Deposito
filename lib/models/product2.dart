class Product2 {
  late String nombre;
  late int cantidadPickeada;
  late int cantidadPedida;
  late String ubicacion;
  late bool isDisabled;

  Product2({
    required this.nombre,
    required this.cantidadPickeada,
    required this.ubicacion,
    required this.cantidadPedida,
    this.isDisabled = false,
  });

  Product2.empty (){
    nombre = '';
    cantidadPickeada = 0;
    cantidadPedida = 0;
    ubicacion = '';
    isDisabled = false;
  }
}
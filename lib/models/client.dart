class Client {
  late int clienteId;
  late String codCliente;
  late String ruc;
  late String nombre;
  late String direccion;
  late String departamento;
  late String telefono1;
  late String telefono2;
  late String fax;
  late String email;
  late String localidad;
  late int departamentoId;
  late int vendedorId;
  late int descuento1;
  late int descuento2;
  late int descuento3;
  late int pagoId;
  late bool suspendido;
  late bool reembolso;
  late int monedaId;
  late int creditoConcedido;
  late int creditoUtilizado;
  late int rubroContable;
  late bool imprime;
  late String observacion;
  late String signo;
  late int descuentoFac1;
  late int descuentoFac3;
  late int descuentoFac2;
  late int tipoListaId;
  late String codTipoLista;
  late String sobreQue;
  late int porcentaje;
  late int tListaSigno;
  late String codTipoCliente;
  late bool controlaDtos;
  late bool soloContado;
  late String agrupador;
  late bool vendFijo;
  late bool clienteContado;
  late int codPais;
  late String pais;
  late String codigo;
  late String modoLista;
  late bool ignorarDtoMax;
  late bool reqDatosAdicionalesOc;
  late bool reqDatosAdicionalesOcnc;
  late bool envio;
  late bool remitos;
  late int monedaIdDef;
  late int tipoClienteId;
  late String tipoLista;
  late int monedaIdLista;

  Client({
    required this.clienteId,
    required this.codCliente,
    required this.ruc,
    required this.nombre,
    required this.direccion,
    required this.departamento,
    required this.telefono1,
    required this.telefono2,
    required this.fax,
    required this.email,
    required this.localidad,
    required this.departamentoId,
    required this.vendedorId,
    required this.descuento1,
    required this.descuento2,
    required this.descuento3,
    required this.pagoId,
    required this.suspendido,
    required this.reembolso,
    required this.monedaId,
    required this.creditoConcedido,
    required this.creditoUtilizado,
    required this.rubroContable,
    required this.imprime,
    required this.observacion,
    required this.signo,
    required this.descuentoFac1,
    required this.descuentoFac2,
    required this.descuentoFac3,
    required this.tipoListaId,
    required this.codTipoLista,
    required this.sobreQue,
    required this.tListaSigno,
    required this.porcentaje,
    required this.codTipoCliente,
    required this.controlaDtos,
    required this.soloContado,
    required this.agrupador,
    required this.vendFijo,
    required this.clienteContado,
    required this.codPais,
    required this.pais,
    required this.codigo,
    required this.modoLista,
    required this.ignorarDtoMax,
    required this.reqDatosAdicionalesOc,
    required this.reqDatosAdicionalesOcnc,
    required this.envio,
    required this.remitos,
    required this.monedaIdDef,
    required this.tipoClienteId,
    required this.tipoLista,
    required this.monedaIdLista,
  });

  static Client fromJson(Map json) => Client(
        clienteId: json["ClienteId"] as int? ?? 0,
        codCliente: json["CodCliente"] as String? ?? '',
        ruc: json["Ruc"] as String? ?? '',
        nombre: json["Nombre"] as String? ?? '',
        direccion: json["Direccion"] as String? ?? '',
        departamento: json["Departamento"] as String? ?? '',
        telefono1: json["Telefono1"] as String? ?? '',
        telefono2: json["Telefono2"] as String? ?? '',
        fax: json["Fax"] as String? ?? '',
        email: json["Email"] as String? ?? '',
        localidad: json["Localidad"] as String? ?? '',
        departamentoId: json["DepartamentoId"] as int? ?? 0,
        vendedorId: json["VendedorId"] as int? ?? 0,
        descuento1: json["Descuento1"] as int? ?? 0,
        descuento2: json["Descuento2"] as int? ?? 0,
        descuento3: json["Descuento3"] as int? ?? 0,
        pagoId: json["PagoId"] as int? ?? 0,
        suspendido: json["Suspendido"] as bool? ?? false,
        reembolso: json["Reembolso"] as bool? ?? false,
        monedaId: json["MonedaId"] as int? ?? 0,
        creditoConcedido: json["CreditoConcedido"] as int? ?? 0,
        creditoUtilizado: json["CreditoUtilizado"] as int? ?? 0,
        rubroContable: json["RubroContable"] as int? ?? 0,
        imprime: json["Imprime"] as bool? ?? false,
        observacion: json["Observacion"] as String? ?? '',
        signo: json["Signo"] as String? ?? '',
        descuentoFac1: json["DescuentoFac1"] as int? ?? 0,
        descuentoFac2: json["DescuentoFac2"] as int? ?? 0,
        descuentoFac3: json["DescuentoFac3"] as int? ?? 0,
        tipoListaId: json["TipoListaId"] as int? ?? 0,
        codTipoLista: json["CodTipoLista"] as String? ?? '',
        sobreQue: json["SobreQue"] as String? ?? '',
        tListaSigno: json["TListaSigno"] as int? ?? 0,
        porcentaje: json["Porcentaje"] as int? ?? 0,
        codTipoCliente: json["CodTipoCliente"] as String? ?? '',
        controlaDtos: json["ControlaDtos"] as bool? ?? false,
        soloContado: json["SoloContado"] as bool? ?? false,
        agrupador: json["Agrupador"] as String? ?? '',
        vendFijo: json["VendFijo"] as bool? ?? false,
        clienteContado: json["ClienteContado"] as bool? ?? false,
        codPais: json["CodPais"] as int? ?? 0,
        pais: json["Pais"] as String? ?? '',
        codigo: json["Codigo"] as String? ?? '',
        modoLista: json["ModoLista"] as String? ?? '',
        ignorarDtoMax: json["IgnorarDtoMax"] as bool? ?? false,
        reqDatosAdicionalesOc: json["ReqDatosAdicionalesOC"] as bool? ?? false,
        reqDatosAdicionalesOcnc: json["ReqDatosAdicionalesOCNC"] as bool? ?? false,
        envio: json["Envio"] as bool? ?? false,
        remitos: json["Remitos"] as bool? ?? false,
        monedaIdDef: json["MonedaIdDef"] as int? ?? 0,
        tipoClienteId: json["TipoClienteId"] as int? ?? 0,
        tipoLista: json["TipoLista"] as String? ?? '',
        monedaIdLista: json["MonedaIdLista"] as int? ?? 0,
      );

  Client.empty() {
    clienteId = 0;
    codCliente = '';
    ruc = '';
    nombre = '';
    direccion = '';
    departamento = '';
    telefono1 = '';
    telefono2 = '';
    fax = '';
    email = '';
    localidad = '';
    departamentoId = 0;
    vendedorId = 0;
    descuento1 = 0;
    descuento2 = 0;
    descuento3 = 0;
    pagoId = 0;
    suspendido = false;
    reembolso = false;
    monedaId = 0;
    creditoConcedido = 0;
    creditoUtilizado = 0;
    rubroContable = 0;
    imprime = false;
    observacion = '';
    signo = '';
    descuentoFac1 = 0;
    descuentoFac2 = 0;
    descuentoFac3 = 0;
    tipoListaId = 0;
    codTipoLista = '';
    sobreQue = '';
    tListaSigno = 0;
    porcentaje = 0;
    codTipoCliente = '';
    controlaDtos = false;
    soloContado = false;
    agrupador = '';
    vendFijo = false;
    clienteContado = false;
    codPais = 0;
    pais = '';
    codigo = '';
    modoLista = '';
    ignorarDtoMax = false;
    reqDatosAdicionalesOc = false;
    reqDatosAdicionalesOcnc = false;
    envio = false;
    remitos = false;
    monedaIdDef = 0;
    tipoClienteId = 0;
    tipoLista = '';
    monedaIdLista = 0;
  }

  @override
  String toString() {
    return 'Instance of Client: $nombre';
  }
}

import 'package:deposito/provider/menu_provider.dart';
import 'package:deposito/provider/product_provider.dart';
import 'package:deposito/services/login_services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:deposito/config/router/router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
const String flavor = String.fromEnvironment('FLAVOR');

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  late bool isObscured;
  final _formKey = GlobalKey<FormState>();
  final passwordFocusNode = FocusNode();
  final userFocusNode = FocusNode();
  String user = '';
  String pass = '';
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final _loginServices = LoginServices();
  bool rememberUser = false;
  List<String> permisos = [];
   
  @override
  void initState() {
    super.initState();
    isObscured = true;
    loadSavedUsername();
  }

  Future<void> loadSavedUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUsername = prefs.getString('username');
    if (savedUsername != null) {
      setState(() {
        usernameController.text = savedUsername;
        rememberUser = true;
      });
    }
  }

  String getLogoPath() {
    switch (flavor.toLowerCase()) {
      case 'familcar':
        return 'images/familcarLogo.png';
      case 'alsur':
        return 'images/alsurLogo.jpg';
      default:
        return 'images/familcarLogo.png'; // fallback
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (MediaQuery.of(context).size.height > MediaQuery.of(context).size.width)... [
                    Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(30),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Image.asset(
                                  getLogoPath(),
                                  fit: BoxFit.fill,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Bienvenido',
                                  style: GoogleFonts.inter(
                                    fontSize: 28,
                                    color: colors.onSurface,
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Inicia Sesion en tu cuenta',
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    color: colors.primary,
                                  ),
                                ),
                                const SizedBox(height: 35),
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        textInputAction: TextInputAction.next,
                                        controller: usernameController,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderSide: const BorderSide(),
                                            borderRadius: BorderRadius.circular(20)
                                          ),
                                          fillColor: colors.surface,
                                          filled: true,
                                          prefixIcon: const Icon(Icons.person),
                                          prefixIconColor: colors.primary,
                                          hintText: 'Ingrese su usuario'
                                        ),
                                        validator: (value) {
                                          if (value!.isEmpty || value.trim().isEmpty){
                                            return 'Ingrese un usuario valido';
                                          }
                                          return null;
                                        },
                                        onSaved:(newValue) => user = newValue!,
                                      ),
                                      const SizedBox(
                                        height: 20,
                                      ),
                                      TextFormField(
                                        controller: passwordController,
                                        obscureText: isObscured,
                                        keyboardType: TextInputType.number, 
                                        focusNode: passwordFocusNode,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderSide: const BorderSide(),
                                            borderRadius: BorderRadius.circular(20)
                                          ),
                                          fillColor: colors.surface,
                                          filled: true,
                                          prefixIcon: const Icon(Icons.lock),
                                          prefixIconColor: colors.primary,
                                          suffixIcon: IconButton(
                                            padding: const EdgeInsetsDirectional.only(end: 12.0),
                                            icon: isObscured
                                              ? Icon(
                                                  Icons.visibility_off,
                                                  color: colors.onSurface,
                                                )
                                              : Icon(Icons.visibility, color: colors.onSurface),
                                              onPressed: () {
                                                setState(() {
                                                  isObscured = !isObscured;
                                                });
                                              },
                                            ),
                                          hintText: 'Ingrese su contraseña'
                                        ),
                                        validator: (value) {
                                          if (value!.isEmpty ||
                                              value.trim().isEmpty) {
                                            return 'Ingrese su contraseña';
                                          }
                                          if (value.length < 6) {
                                            return 'Contraseña invalida';
                                          }
                                          return null;
                                        },
                                        onFieldSubmitted: (value) async {
                                          await login(context);
                                        },
                                        onSaved: (newValue) => pass = newValue!,
                                      ),
                                      const SizedBox(
                                        height: 20,
                                      ),
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            rememberUser = !rememberUser; // Invertir el valor del checkbox
                                          });
                                        },
                                        child: Row(
                                          children: [
                                            CheckboxTheme(
                                              data: CheckboxThemeData(
                                                fillColor: WidgetStatePropertyAll(colors.onPrimary),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(4), // Bordes redondeados
                                                ),
                                                side: BorderSide(
                                                  color: colors.onSurface, // Color del contorno
                                                  width: 2, // Grosor del contorno
                                                ),
                                              ),
                                              child: Checkbox(
                                                value: rememberUser,
                                                activeColor: colors.secondary,
                                                onChanged: (value) {
                                                  setState(() {
                                                    rememberUser = value!;
                                                  });
                                                },
                                              ),
                                            ),
                                            Text('Recordar usuario', style: TextStyle(color: colors.onSurface),),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                ),
                                const SizedBox(height: 20,),
                                ElevatedButton(
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStatePropertyAll(colors.surface),
                                    elevation: const WidgetStatePropertyAll(10),
                                    shape: const WidgetStatePropertyAll(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.horizontal(
                                          left: Radius.circular(50),
                                          right: Radius.circular(50)
                                        )
                                      )
                                    )
                                  ),
                                  onPressed: () async{
                                    await login(context);
                                  },
                                  child: Text(
                                    'Iniciar Sesión',
                                    style: TextStyle(
                                      color: colors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20
                                    ),
                                  )
                                ),
                                FutureBuilder(
                                  future: PackageInfo.fromPlatform(),
                                  builder: (BuildContext context, AsyncSnapshot<PackageInfo> snapshot) {
                                    if (snapshot.hasData) {
                                      return Column(
                                        children: [
                                          Text(
                                            'Versión ${snapshot.data!.version}',/*(Build ${snapshot.data!.buildNumber})*/
                                            style: const TextStyle(color: Colors.black),
                                          ),
                                          const Text(
                                            '2025.07.21+1',
                                            style: TextStyle(color: Colors.black),
                                          ),
                                        ],
                                      );
                                    } else {
                                      return const Text('Cargando la app...');
                                    }
                                  }
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  ] else ...[
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SizedBox(
                             height: MediaQuery.of(context).size.height * 0.6,
                             width: MediaQuery.of(context).size.width / 2,
                              child:Image.asset(
                                'images/familcarLogo.png',
                                fit: BoxFit.fill,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 18),
                                padding: const EdgeInsets.symmetric(horizontal: 45),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Bienvenido',
                                      style: GoogleFonts.inter(
                                        fontSize: 28,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w900
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Inicia Sesion en tu cuenta',
                                      style: GoogleFonts.inter(
                                        fontSize: 17,
                                        color: colors.primary,
                                        fontWeight: FontWeight.w700
                                      ),
                                    ),
                                    const SizedBox(height: 35),
                                    Form(
                                      key: _formKey,
                                      child: Column(
                                        children: [
                                          TextFormField(
                                            controller: usernameController,
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(
                                                borderSide: const BorderSide(),
                                                borderRadius: BorderRadius.circular(20)
                                              ),
                                            fillColor: colors.surface,
                                            filled: true,
                                            prefixIcon: const Icon(Icons.person),
                                            prefixIconColor: colors.primary,
                                            hintText: 'Ingrese su usuario'),
                                            validator: (value) {
                                              if (value!.isEmpty ||
                                                value.trim().isEmpty) {
                                                return 'Ingrese un usuario valido';
                                              }
                                              return null;
                                            },
                                            onSaved: (newValue) => user = newValue!
                                          ),
                                          const SizedBox(height: 20,),
                                          TextFormField(
                                            controller: passwordController,
                                            obscureText: isObscured,
                                            focusNode: passwordFocusNode,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(
                                                borderSide: const BorderSide(),
                                                borderRadius:BorderRadius.circular(20)
                                              ),
                                              fillColor: colors.surface,
                                              filled: true,
                                              prefixIcon: const Icon(Icons.lock),
                                              prefixIconColor: colors.primary, //const Color.fromARGB(255, 41, 146, 41)  
                                              suffixIcon: IconButton(
                                                padding: const EdgeInsetsDirectional.only(end: 12.0),
                                              icon: isObscured? 
                                                Icon(
                                                  Icons.visibility_off,
                                                  color: colors.onSurface,
                                                ) : Icon(
                                                  Icons.visibility,
                                                  color: colors.onSurface
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    isObscured = !isObscured;
                                                  });
                                                },
                                              ),
                                              hintText: 'Ingrese su contraseña'
                                            ),
                                            validator: (value) {
                                              if (value!.isEmpty || value.trim().isEmpty) {
                                                return 'Ingrese su contraseña';
                                              }
                                              if (value.length < 6) {
                                               return 'Contraseña invalida';
                                              }
                                              return null;
                                            },
                                            onFieldSubmitted: (value) async {
                                             await login(context);
                                            },
                                            onSaved: (newValue) => pass = newValue!
                                          ),
                                          const SizedBox(
                                            height: 20,
                                          ),
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                rememberUser = !rememberUser; // Invertir el valor del checkbox
                                              });
                                            },
                                            child: Row(
                                              children: [
                                                CheckboxTheme(
                                                  data: CheckboxThemeData(
                                                    fillColor: WidgetStatePropertyAll(colors.onPrimary),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(4), // Bordes redondeados
                                                    ),
                                                    side: BorderSide(
                                                      color: colors.onError, // Color del contorno
                                                      width: 2, // Grosor del contorno
                                                    ),
                                                  ),
                                                  child: Checkbox(
                                                    value: rememberUser,
                                                    activeColor: colors.secondary,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        rememberUser = value!;
                                                      });
                                                    },
                                                  ),
                                                ),
                                                Text('Recordar usuario', style: TextStyle(color: colors.onError),),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 40,),
                                          ElevatedButton(
                                            style: ButtonStyle(
                                              backgroundColor: WidgetStatePropertyAll(colors.surface),
                                              elevation: const WidgetStatePropertyAll(10),
                                              shape: const WidgetStatePropertyAll(
                                                RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.horizontal(
                                                    left: Radius.circular(50),
                                                    right: Radius.circular(50),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            onPressed: () async {
                                              await login(context);
                                            },
                                            child: Padding(
                                              padding:const EdgeInsets.symmetric(vertical: 8.5),
                                              child: Text('Iniciar Sesión',
                                                style: TextStyle(
                                                  color: colors.primary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 25,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    ),
                                    const SizedBox(height: 10,),
                                    FutureBuilder(
                                      future: PackageInfo.fromPlatform(),
                                      builder: (BuildContext context, AsyncSnapshot<PackageInfo> snapshot) {
                                        if (snapshot.hasData) {
                                          return Column(
                                            children: [
                                              Text(
                                                'Versión ${snapshot.data!.version}',
                                                style: const TextStyle(color: Colors.black),
                                              ),
                                              const Text(
                                                '2025.07.21+1',
                                                style: TextStyle(color: Colors.black),
                                              ),
                                            ],
                                          );
                                        } else {
                                          return const Text('Cargando la app...');
                                        }
                                      }
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> login(BuildContext context) async {
    final colors = Theme.of(context).colorScheme;
    await _loginServices.login(
      usernameController.text,
      passwordController.text,
      context,
    );

    if (_formKey.currentState?.validate() == true) {
      var statusCode = await _loginServices.getStatusCode();

      if (statusCode == 1) {
        if (rememberUser) {
          // Guardar el nombre de usuario en SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('username', usernameController.text);
        } else {
          // Si el checkbox no está seleccionado, borrar el nombre de usuario guardado
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.remove('username');
        }
        permisos = await _loginServices.getPermisos(context, context.read<ProductProvider>().token);
        Provider.of<MenuProvider>(context, listen: false).loadQuickAccess();
        Provider.of<ProductProvider>(context, listen: false).setPermisos(permisos);
        appRouter.go('/almacen');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Credenciales inválidas. Intente nuevamente.'),
            backgroundColor: colors.onError,
          ),
        );  
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Credenciales inválidas. Intente nuevamente.'),
          backgroundColor: colors.onError,
        ),
      );
      print('Credenciales inválidas. Intente nuevamente.');
    }
  }
}

import 'package:flutter/material.dart';
import '../../Contenido_del_tema/colores.dart';
import '../../Contenido_del_tema/boton_principal.dart';
import '../../Contenido_del_tema/tarjeta_contenedor.dart';

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreController;
  late TextEditingController _usuarioController;
  late TextEditingController _fraseController;

  @override
  void initState() {
    super.initState();
    // Valores iniciales según la interfaz de Figma
    _nombreController = TextEditingController(text: 'El Diego');
    _usuarioController = TextEditingController(text: '@diego.crece');
    _fraseController = TextEditingController(
      text: 'Pequeños pasos, raíces fuertes.',
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _usuarioController.dispose();
    _fraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColores.fondoClaro,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColores.textoOscuro),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Editar Perfil',
          style: TextStyle(
            color: AppColores.textoOscuro,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Foto de Perfil con opción de cambio
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColores.verdePrincipal,
                          width: 3,
                        ),
                        image: const DecorationImage(
                          image: NetworkImage(
                            'https://i.pravatar.cc/150?img=12',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColores.verdePrincipal,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Formulario de Datos
              TarjetaContenedor(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCampoTexto(
                      label: 'Nombre completo',
                      controller: _nombreController,
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    _buildCampoTexto(
                      label: 'Nombre de usuario',
                      controller: _usuarioController,
                      icon: Icons.alternate_email,
                    ),
                    const SizedBox(height: 16),
                    _buildCampoTexto(
                      label: 'Frase motivacional / Bio',
                      controller: _fraseController,
                      icon: Icons.edit_note,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Botón para Guardar Cambios
              BotonPrincipal(
                texto: 'Guardar cambios',
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Perfil actualizado correctamente'),
                        backgroundColor: AppColores.verdePrincipal,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampoTexto({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColores.textoOscuro,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, color: AppColores.textoOscuro),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColores.textoGris, size: 20),
            filled: true,
            fillColor: AppColores.fondoClaro,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

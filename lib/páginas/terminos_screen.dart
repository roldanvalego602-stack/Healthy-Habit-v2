import 'package:flutter/material.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _hasAccepted = false;

  // Paleta de colores oficial
  static const Color green = Color(0xFF198568);
  static const Color navy = Color(0xFF172B36);
  static const Color background = Color(0xFFF7F9F8);
  static const Color textMuted = Color(0xFF7A869A);
  static const Color borderCard = Color(0xFFE5EEE9);

  void _onAcceptPressed() {
    if (!_hasAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, marca la casilla de aceptación para continuar.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Gracias por aceptar los Términos y Condiciones!'),
        backgroundColor: green,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/mascot/healthy.png',
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.eco_rounded, color: green, size: 22),
            ),
            const SizedBox(width: 8),
            const Text(
              'Healthy Habit',
              style: TextStyle(
                color: navy,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header del documento
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Términos y Condiciones',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: const [
                      Icon(Icons.calendar_today_outlined,
                          size: 13, color: textMuted),
                      SizedBox(width: 6),
                      Text(
                        'Última actualización: 23 de octubre de 2026',
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Contenedor scrolleable con el texto completo
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: borderCard, width: 1),
                ),
                child: Scrollbar(
                  thumbVisibility: true,
                  thickness: 4,
                  radius: const Radius.circular(8),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('1. Aceptación de los términos'),
                        _buildParagraph(
                          'Al registrarse, acceder o utilizar la aplicación Healthy-Habit, en adelante «la Aplicación», el usuario declara haber leído y aceptado estos Términos y Condiciones.',
                        ),
                        _buildParagraph(
                          'Si el usuario no está de acuerdo con alguna de las disposiciones, deberá abstenerse de utilizar la Aplicación.',
                        ),
                        _buildParagraph(
                          'La aceptación deberá realizarse mediante una acción afirmativa, como seleccionar una casilla de aceptación. La casilla no deberá estar marcada previamente.',
                        ),

                        _buildSectionTitle('2. Descripción del servicio'),
                        _buildParagraph(
                          'Healthy-Habit es una aplicación diseñada para ayudar a los usuarios a organizar, registrar y dar seguimiento a sus hábitos y actividades cotidianas.',
                        ),
                        _buildParagraph('Entre sus funcionalidades se pueden incluir:'),
                        _buildBulletPoint('Registro y seguimiento de hábitos personales.'),
                        _buildBulletPoint('Visualización del progreso y cumplimiento de objetivos.'),
                        _buildBulletPoint('Seguimiento de rachas y estadísticas de actividad.'),
                        _buildBulletPoint('Obtención de experiencia (XP), niveles, logros e insignias.'),
                        _buildBulletPoint('Acumulación y utilización de monedas virtuales, como Habit Coins.'),
                        _buildBulletPoint('Acceso a una tienda virtual y opciones de personalización del perfil.'),
                        _buildBulletPoint('Visualización de recomendaciones, mensajes motivacionales y otros recursos relacionados con la formación de hábitos.'),
                        _buildParagraph(
                          'Las funciones disponibles podrán variar según la versión de la Aplicación.',
                        ),

                        _buildSectionTitle('3. Requisitos de uso'),
                        _buildParagraph(
                          'El usuario se compromete a proporcionar información veraz cuando sea necesario para utilizar las funcionalidades de la Aplicación y a mantener actualizada la información de su cuenta.',
                        ),
                        _buildParagraph(
                          'Cuando el usuario sea menor de edad, el uso de la Aplicación deberá realizarse conforme a la legislación aplicable y, cuando corresponda, con la intervención o autorización de su madre, padre o tutor legal.',
                        ),
                        _buildParagraph(
                          'El usuario será responsable de mantener la confidencialidad de sus credenciales de acceso y de las actividades realizadas desde su cuenta, salvo en los casos en que la responsabilidad corresponda legalmente al proveedor del servicio.',
                        ),

                        _buildSectionTitle('4. Uso adecuado de la Aplicación'),
                        _buildParagraph(
                          'El usuario se compromete a utilizar Healthy-Habit de manera responsable y conforme a la legislación aplicable.',
                        ),
                        _buildParagraph('Queda prohibido:'),
                        _buildBulletPoint('Utilizar la Aplicación con fines ilícitos o fraudulentos.'),
                        _buildBulletPoint('Intentar acceder sin autorización a cuentas, sistemas o información de otros usuarios.'),
                        _buildBulletPoint('Manipular deliberadamente los registros, las recompensas o los mecanismos de progreso para obtener ventajas indebidas.'),
                        _buildBulletPoint('Introducir código malicioso o realizar acciones que comprometan la seguridad o disponibilidad del servicio.'),
                        _buildBulletPoint('Utilizar la Aplicación para acosar, amenazar o perjudicar a otras personas.'),
                        _buildBulletPoint('Copiar, modificar, distribuir o explotar comercialmente los componentes protegidos de la Aplicación sin autorización, salvo cuando la ley lo permita.'),
                        _buildParagraph(
                          'El incumplimiento podrá dar lugar a medidas proporcionales, incluida la restricción o suspensión de la cuenta, conforme a la legislación aplicable y sin perjuicio de los derechos del usuario.',
                        ),

                        _buildSectionTitle('5. Hábitos, progreso y contenido motivacional'),
                        _buildParagraph(
                          'Healthy-Habit tiene como finalidad apoyar la organización personal y la formación de hábitos. Los registros, estadísticas, rachas, niveles y recomendaciones se proporcionan como herramientas de seguimiento y motivación.',
                        ),
                        _buildParagraph(
                          'El usuario reconoce que el progreso mostrado depende de los datos registrados, de las funciones disponibles y del funcionamiento de la Aplicación. No se garantiza un resultado específico ni la adquisición de un hábito en un plazo determinado.',
                        ),
                        _buildParagraph(
                          'El contenido motivacional no constituye asesoramiento médico, psicológico, nutricional ni profesional. La Aplicación no sustituye la evaluación o atención de especialistas cuando esta sea necesaria.',
                        ),
                        _buildParagraph(
                          'El usuario deberá adaptar sus actividades a sus circunstancias y evitar prácticas que puedan poner en riesgo su salud o seguridad.',
                        ),

                        _buildSectionTitle('6. XP, niveles, logros y monedas virtuales'),
                        _buildParagraph(
                          'La experiencia (XP), los niveles, las rachas, las insignias, los logros y las monedas virtuales son elementos digitales destinados a representar el progreso y la participación dentro de Healthy-Habit.',
                        ),
                        _buildParagraph('Salvo que se indique expresamente lo contrario:'),
                        _buildBulletPoint('Estos elementos no representan dinero real, depósitos, inversiones ni derechos de cobro.'),
                        _buildBulletPoint('Las monedas virtuales no son dinero electrónico ni un medio de pago de aceptación general.'),
                        _buildBulletPoint('No pueden canjearse por dinero real ni transferirse a terceros.'),
                        _buildBulletPoint('Su obtención y utilización dependen de las reglas y funcionalidades habilitadas en la Aplicación.'),
                        _buildBulletPoint('Los saldos, recompensas y progresos pueden ajustarse cuando sea necesario corregir errores técnicos, prevenir fraudes o mantener el funcionamiento del servicio, respetando los derechos aplicables.'),
                        _buildParagraph(
                          'Cualquier cambio relevante en las reglas de recompensas deberá comunicarse de manera adecuada cuando corresponda.',
                        ),

                        _buildSectionTitle('7. Tienda virtual y personalización'),
                        _buildParagraph(
                          'La tienda de Healthy-Habit puede ofrecer elementos digitales, como marcos, banners, títulos, insignias u otras opciones de personalización.',
                        ),
                        _buildParagraph(
                          'La disponibilidad de estos elementos puede variar. Su obtención no implica la adquisición de derechos de propiedad sobre la Aplicación ni sobre sus contenidos.',
                        ),
                        _buildParagraph(
                          'Si en el futuro se habilitan compras con dinero real, estas estarán sujetas a condiciones específicas, información de precios, medios de pago, políticas de cancelación y demás requisitos legales aplicables. La existencia de monedas virtuales no implica por sí misma que dichas compras estén disponibles.',
                        ),

                        _buildSectionTitle('8. Cuenta y seguridad'),
                        _buildParagraph(
                          'El usuario deberá utilizar su cuenta de forma personal y mantener protegidos sus datos de acceso.',
                        ),
                        _buildParagraph(
                          'Si detecta un uso no autorizado de su cuenta o un posible incidente de seguridad, deberá comunicarlo al responsable de Healthy-Habit a través del canal de contacto que se habilite.',
                        ),
                        _buildParagraph(
                          'El responsable podrá adoptar medidas razonables para proteger las cuentas, investigar actividades sospechosas y mantener la integridad del servicio.',
                        ),

                        _buildSectionTitle('9. Privacidad y protección de datos personales'),
                        _buildParagraph(
                          'Healthy-Habit deberá tratar los datos personales de acuerdo con la legislación de protección de datos aplicable y con su Aviso de Privacidad.',
                        ),
                        _buildParagraph(
                          'Los datos que se recopilen, las finalidades del tratamiento, los mecanismos de consentimiento, los plazos de conservación y los procedimientos para ejercer los derechos que correspondan deberán explicarse en dicho aviso.',
                        ),
                        _buildParagraph(
                          'El usuario podrá consultar el Aviso de Privacidad en el apartado correspondiente de la Aplicación.',
                        ),
                        _buildParagraph(
                          'La aceptación de estos Términos y Condiciones no sustituye los consentimientos específicos que legalmente sean necesarios para el tratamiento de datos personales.',
                        ),
                        _buildNoticeBox(
                          'Aviso: antes de publicar la Aplicación, deberá incorporarse un Aviso de Privacidad real que describa las prácticas efectivas de recopilación, uso, almacenamiento y protección de datos de Healthy-Habit.',
                        ),

                        _buildSectionTitle('10. Propiedad intelectual'),
                        _buildParagraph(
                          'Los elementos de Healthy-Habit, incluidos su diseño, interfaz, logotipos, textos, ilustraciones, iconos, recursos gráficos, código y otros materiales, podrán estar protegidos por derechos de propiedad intelectual.',
                        ),
                        _buildParagraph(
                          'Salvo autorización expresa o disposición legal aplicable, el usuario no podrá reproducirlos, distribuirlos, modificarlos ni explotarlos comercialmente.',
                        ),
                        _buildParagraph(
                          'El uso de la Aplicación no transfiere al usuario la titularidad de dichos derechos.',
                        ),
                        _buildParagraph(
                          'Los materiales de terceros utilizados en la Aplicación podrán estar sujetos a sus propias licencias y condiciones.',
                        ),

                        _buildSectionTitle('11. Disponibilidad y modificaciones del servicio'),
                        _buildParagraph(
                          'Healthy-Habit podrá recibir actualizaciones, mejoras, cambios de diseño o modificaciones funcionales.',
                        ),
                        _buildParagraph(
                          'Aunque se procurará mantener el servicio disponible, no se garantiza que funcione de manera ininterrumpida, libre de errores o compatible con todos los dispositivos.',
                        ),
                        _buildParagraph(
                          'Podrán realizarse interrupciones por mantenimiento, actualizaciones, incidentes técnicos o circunstancias ajenas al control razonable del responsable.',
                        ),
                        _buildParagraph(
                          'Cuando sea viable y corresponda, se procurará informar de las interrupciones relevantes.',
                        ),

                        _buildSectionTitle('12. Suspensión y cancelación de cuentas'),
                        _buildParagraph(
                          'El usuario podrá dejar de utilizar la Aplicación y solicitar la cancelación de su cuenta mediante los mecanismos que se habiliten.',
                        ),
                        _buildParagraph(
                          'El responsable podrá restringir o suspender una cuenta cuando existan motivos legítimos, como incumplimientos de estos términos, riesgos de seguridad o indicios de fraude, de acuerdo con la legislación aplicable.',
                        ),
                        _buildParagraph(
                          'La eliminación de una cuenta y la supresión de los datos personales se gestionarán conforme a las políticas informadas y a las obligaciones legales de conservación que correspondan.',
                        ),
                        _buildParagraph(
                          'Los procedimientos para solicitar la eliminación de la cuenta deberán estar disponibles o comunicarse claramente a los usuarios.',
                        ),

                        _buildSectionTitle('13. Limitación de responsabilidad'),
                        _buildParagraph(
                          'Healthy-Habit se ofrece como una herramienta de apoyo para la organización y el seguimiento de hábitos.',
                        ),
                        _buildParagraph(
                          'En la medida permitida por la legislación aplicable, el responsable no garantiza que la Aplicación satisfaga todas las necesidades particulares del usuario, que los datos registrados estén siempre disponibles o que el uso del servicio produzca resultados específicos.',
                        ),
                        _buildParagraph(
                          'Esta disposición no excluye ni limita las responsabilidades, garantías o derechos que legalmente no puedan excluirse o limitarse, incluidos los derechos irrenunciables de los consumidores cuando resulten aplicables.',
                        ),

                        _buildSectionTitle('14. Cambios en los términos'),
                        _buildParagraph(
                          'Estos Términos y Condiciones podrán actualizarse para reflejar cambios funcionales, técnicos, operativos o legales.',
                        ),
                        _buildParagraph(
                          'La versión vigente deberá estar disponible para consulta dentro de la Aplicación o mediante un enlace accesible.',
                        ),
                        _buildParagraph(
                          'Cuando una modificación requiera una nueva aceptación por su relevancia o por disposición legal, se solicitará al usuario antes de que continúe utilizando las funciones afectadas.',
                        ),
                        _buildParagraph(
                          'La fecha de actualización se indicará al inicio del documento.',
                        ),

                        _buildSectionTitle('15. Legislación aplicable y resolución de controversias'),
                        _buildParagraph(
                          'Estos términos se interpretarán conforme a la legislación aplicable en México, sin perjuicio de las normas imperativas que correspondan al domicilio del usuario y de los derechos que le reconozca la ley.',
                        ),
                        _buildParagraph(
                          'Las controversias se procurarán resolver mediante comunicación entre las partes. Cuando no sea posible alcanzar una solución, podrán utilizarse las vías administrativas o judiciales competentes.',
                        ),
                        _buildParagraph(
                          'Ninguna disposición de este documento pretende privar al usuario de los derechos que legalmente le correspondan.',
                        ),

                        _buildSectionTitle('16. Contacto'),
                        _buildParagraph(
                          'Para consultas, reportes o solicitudes relacionadas con estos términos, el usuario podrá comunicarse con el responsable de Healthy-Habit mediante los siguientes datos:',
                        ),
                        _buildBulletPoint('Responsable o titular del proyecto: Equipo Healthy Habit'),
                        _buildBulletPoint('Correo electrónico de contacto: soporte@healthyhabit.com'),
                        _buildBulletPoint('Domicilio o medio de contacto legal: Durango, México'),
                        _buildBulletPoint('Aviso de Privacidad: Disponible en Ajustes → Privacidad'),

                        _buildSectionTitle('17. Declaración de aceptación'),
                        _buildParagraph(
                          'Al seleccionar la casilla «He leído y acepto los Términos y Condiciones», el usuario declara que tuvo acceso a este documento, que pudo consultarlo antes de continuar y que acepta las condiciones de uso aquí descritas.',
                        ),
                        _buildParagraph(
                          'La aceptación se registrará conforme al mecanismo implementado por Healthy-Habit y a las disposiciones legales aplicables.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Footer con Casilla de verificación, Enlace a Privacidad y Botón
            Container(
              padding: const EdgeInsets.all(20),
              color: background,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _hasAccepted,
                          onChanged: (val) {
                            setState(() {
                              _hasAccepted = val ?? false;
                            });
                          },
                          activeColor: green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'He leído y acepto los Términos y Condiciones de Healthy-Habit.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: navy,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Dirigiéndose al Aviso de Privacidad...'),
                        ),
                      );
                    },
                    child: const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Consulta también nuestro Aviso de Privacidad.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: green,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _hasAccepted ? _onAcceptPressed : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        disabledBackgroundColor: const Color(0xFFC4E5D8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Aceptar y continuar',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: navy,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: textMuted,
          height: 1.45,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: green, fontWeight: FontWeight.bold, fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                color: textMuted,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeBox(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE5B4)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11.5,
          color: Color(0xFFB47200),
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      ),
    );
  }
}
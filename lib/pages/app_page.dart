import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shake/shake.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:speech_to_text/speech_to_text.dart' as stts;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:battery_plus/battery_plus.dart';

import 'package:blind_assistant_app/services/backend_service.dart';

class AppPage extends StatefulWidget {
  const AppPage({super.key});

  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  int counter = 0;
  late ShakeDetector detector;
  // =====*****_____ Var: Activar el microfono _____*****===== //
  var _speechToText = stts.SpeechToText();
  bool isListening = false;
  String text = "Presionar Por favor";
  // =====*****_____ Var: Texto a Voz _____*****===== //
  final FlutterTts flutterTts = FlutterTts();
  Battery battery = Battery();

  Future<void> speak(String text) async {
    await flutterTts.setLanguage('es-ES');
    await flutterTts.setPitch(1);
    await flutterTts.speak(text);
  }

  // =====*****_____ Apagar Microfono y el detector _____*****===== //
  @override
  void dispose() {
    detector.stopListening();
    super.dispose();
  }

  // =====*****_____ Inicio de la App _____*****===== //
  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    speak('Bienvenido a la aplicación mEncuentras');
    detector = ShakeDetector.autoStart(
      onPhoneShake: () {
        listen();
      },
      minimumShakeCount: 1,
      shakeSlopTimeMS: 500,
      shakeCountResetTime: 3000,
      shakeThresholdGravity: 2.7,
    );
    _speechToText = stts.SpeechToText();
  }

  // =====*****_____ Función de escuchar cuando se agita el celular _____*****===== //
  void listen() async {
    if (!isListening) {
      bool available = await _speechToText.initialize(
        onStatus: (status) {
          // ignore: avoid_print
          print(status);
        },
        // ignore: avoid_print
        onError: (errorNotification) => print("$errorNotification"),
      );
      if (available) {
        setState(
          () {
            isListening = true;
          },
        );
        _speechToText.listen(
          onResult: (result) => setState(
            () async {
              text = result.recognizedWords;
              await send(text);
            },
          ),
        );
      }
    } else {
      setState(() {
        isListening = false;
      });
      speak('Usted apagó el micrófono');
      _speechToText.stop();
      // _updatePosition();
    }
  }

  // =====*****_____ Función de enviar datos al servidor _____*****===== //
  Future<void> send(String text) async {
    text = text.toLowerCase();
    print(text);
    if (text.contains("batería") || text.contains("bateria")) {
      int batteryLevel = await battery.batteryLevel;
      String cadenaFinal = clearBatteryString(text);
      String response = await BackendService.httpConnetPost(
        message: cadenaFinal,
        battery: batteryLevel.toString(),
      );
      speak(response);
    } else if (text.contains('hora')) {
      String hour = getHourString();
      final response = await BackendService.httpConnetPost(
        message: text,
        hour: hour,
      );
      await speak(response);
    }
    if (text.contains('fecha') ||
        text.contains('día') ||
        text.contains('dia')) {
      String date = DateFormat('EEEE, d \'de\' MMMM, \'de\' yyyy', 'es').format(
        DateTime.now(),
      );
      String response = await BackendService.httpConnetPost(
        message: text,
        date: date,
      );
      await speak(response);
    }
  }

  String clearBatteryString(String text) {
    // Eliminar las comas
    String cadenaSinComas = text.replaceAll(',', '');

    // Reemplazar las tildes por vocales normales
    String cadenaSinTildes = cadenaSinComas
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');

    // Borrar los signos de interrogación
    String cadenaFinal =
        cadenaSinTildes.replaceAll('?', '').replaceAll('¿', '');
    return cadenaFinal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenido al Asistente'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Center(child: Text(text)),
        ],
      ),
      floatingActionButton: AvatarGlow(
        animate: isListening,
        repeat: isListening,
        endRadius: 80,
        glowColor: Colors.red,
        duration: const Duration(milliseconds: 1000),
        child: FloatingActionButton(
          onPressed: () => listen(),
          child: Icon(isListening ? Icons.mic : Icons.mic_none),
        ),
      ),
    );
  }

  String getHourString() {
    String hour = DateTime.now().hour.toString();
    String minute = DateTime.now().minute.toString();
    String hourFinal = '$hour:$minute';
    return hourFinal;
  }
}

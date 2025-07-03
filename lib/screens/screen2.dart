import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:duolingo_clone_project/screens/screen3.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lottie/lottie.dart';

class ScreenTwo extends StatefulWidget {
  final int levelNumber;

  const ScreenTwo({super.key, required this.levelNumber});

  @override
  State<ScreenTwo> createState() => _ScreenTwoState();
}

class _ScreenTwoState extends State<ScreenTwo> {
  final AudioPlayer player = AudioPlayer();
  final FlutterTts flutterTts = FlutterTts();
  late OnDeviceTranslator translator;

  String subtitle = '';
  String questionEn = '';
  String questionTranslated = '';
  List<Map<String, dynamic>> options = [];

  String selectedOption = '';
  bool isCorrectAnswerSelected = false;

  static const Color greenPrimary = Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    await _initTranslator();
    await _initializeTts();
    await _fetchTask();
  }

  Future<void> _initTranslator() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    final userLang = userDoc['language'] ?? 'German';
    final targetLang = _mapLanguageToEnum(userLang);

    translator = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.english,
      targetLanguage: targetLang,
    );
  }

  TranslateLanguage _mapLanguageToEnum(String lang) {
    switch (lang.toLowerCase()) {
      case 'german':
        return TranslateLanguage.german;
      case 'spanish':
        return TranslateLanguage.spanish;
      case 'french':
        return TranslateLanguage.french;
      case 'italian':
        return TranslateLanguage.italian;
      case 'korean':
        return TranslateLanguage.korean;
      default:
        return TranslateLanguage.german; // fallback
    }
  }

  Future<void> _initializeTts() async {
    final ttsLang = _getTtsCode(translator.targetLanguage);
    await flutterTts.setLanguage(ttsLang);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
  }

  String _getTtsCode(TranslateLanguage lang) {
    switch (lang) {
      case TranslateLanguage.spanish:
        return 'es';
      case TranslateLanguage.french:
        return 'fr';
      case TranslateLanguage.italian:
        return 'it';
      case TranslateLanguage.korean:
        return 'ko';
      default:
        return 'de'; // German fallback
    }
  }

  @override
  void dispose() {
    player.dispose();
    flutterTts.stop();
    translator.close();
    super.dispose();
  }

  Future<void> _fetchTask() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('levels')
          .doc('level_${widget.levelNumber}')
          .collection('tasks')
          .doc('task_2')
          .get();

      if (doc.exists) {
        subtitle = doc['subtitle'] ?? '';
        questionEn = doc['question'] ?? '';

        final originalOptions =
        List<Map<String, dynamic>>.from(doc['options'] ?? []);

        questionTranslated = await translator.translateText(questionEn);

        options = [];
        for (var opt in originalOptions) {
          final translatedText = await translator.translateText(opt['text']);
          options.add({
            'textEn': opt['text'],
            'textTranslated': translatedText,
            'isCorrect': opt['isCorrect'],
          });
        }

        setState(() {});
      }
    } catch (e) {
      debugPrint('Error fetching or translating task: $e');
    }
  }

  void _speak(String text) async {
    if (text.isNotEmpty) {
      await flutterTts.speak(text);
    }
  }

  void _handleSelection(String textTranslated) {
    setState(() {
      selectedOption = textTranslated;
    });
  }

  void _checkAnswer() {
    if (selectedOption.isEmpty) return;

    final selectedOptionData = options.firstWhere(
          (opt) => opt['textTranslated'] == selectedOption,
      orElse: () => {},
    );

    final isCorrect = selectedOptionData['isCorrect'] ?? false;

    _playFeedback(isCorrect);

    setState(() {
      isCorrectAnswerSelected = isCorrect;
    });
  }

  void _playFeedback(bool isCorrect) {
    final soundAsset =
    isCorrect ? 'assets/sound/success.mp3' : 'assets/sound/fail.mp3';

    player.setAsset(soundAsset).then((_) => player.play());

    final animationType = isCorrect ? 'success' : 'failure';
    _showResultBottomSheet(animationType, isCorrect);
  }

  void _showResultBottomSheet(String animationType, bool isCorrect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.4,
          maxChildSize: 0.6,
          builder: (_, controller) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    animationType == 'success'
                        ? 'assets/animation/correct.json'
                        : 'assets/animation/fail.json',
                    height: 150,
                  ),
                  const SizedBox(height: 20),
                  if (isCorrect)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ScreenThree(levelNumber: widget.levelNumber),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: greenPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'CONTINUE',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const backgroundGradient = LinearGradient(
      colors: [Color(0xFFE8F5E9), Colors.white],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: backgroundGradient,
        ),
        child: SafeArea(
          child: options.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.black87, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius:
                        const BorderRadius.all(Radius.circular(30)),
                        child: const LinearProgressIndicator(
                          value: 0.5,
                          backgroundColor: Colors.blueGrey,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              greenPrimary),
                          minHeight: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.volume_up,
                          color: greenPrimary, size: 32),
                      onPressed: () => _speak(questionTranslated),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.grey.shade300, width: 1.5),
                        ),
                        child: Text(
                          "$questionTranslated\n[$questionEn]",
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView.builder(
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final isSelected =
                          selectedOption == option['textTranslated'];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () =>
                              _handleSelection(option['textTranslated']),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 20),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? greenPrimary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? greenPrimary
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              "${option['textTranslated']}\n[${option['textEn']}]",
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedOption.isEmpty
                        ? null
                        : _checkAnswer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: greenPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'CHECK',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

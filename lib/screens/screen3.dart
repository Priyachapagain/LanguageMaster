import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:duolingo_clone_project/screens/screen4.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lottie/lottie.dart';

class ScreenThree extends StatefulWidget {
  final int levelNumber;

  const ScreenThree({super.key, required this.levelNumber});

  @override
  State<ScreenThree> createState() => _ScreenThreeState();
}

class _ScreenThreeState extends State<ScreenThree> {
  final AudioPlayer player = AudioPlayer();
  final FlutterTts flutterTts = FlutterTts();
  late OnDeviceTranslator translator;

  static const Color greenPrimary = Color(0xFF4CAF50);

  String subtitle = '';
  String questionEn = '';
  List<String> answerEn = [];
  List<String> answerTranslated = [];
  List<Map<String, String>> shuffledWords = [];
  List<Map<String, String>> selectedWords = [];

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
          .doc('task_3')
          .get();

      if (doc.exists) {
        subtitle = doc['subtitle'] ?? '';
        questionEn = doc['question'] ?? '';
        answerEn = List<String>.from(doc['answer'] ?? []);

        answerTranslated = [];
        for (final word in answerEn) {
          final translated = await translator.translateText(word);
          answerTranslated.add(translated);
        }

        shuffledWords = [];
        for (var i = 0; i < answerEn.length; i++) {
          shuffledWords.add({
            'en': answerEn[i],
            'translated': answerTranslated[i],
          });
        }
        shuffledWords.shuffle();

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

  void _selectWord(Map<String, String> word) {
    setState(() {
      selectedWords.add(word);
      shuffledWords.remove(word);
    });
  }

  void _removeWord(Map<String, String> word) {
    setState(() {
      shuffledWords.add(word);
      selectedWords.remove(word);
    });
  }

  void _checkAnswer() {
    final selected = selectedWords.map((w) => w['translated']).toList();
    final correct = answerTranslated;

    final isCorrect = selected.join(' ') == correct.join(' ');

    _playFeedback(isCorrect);
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
                              builder: (_) => ScreenFour(levelNumber: widget.levelNumber),
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
          child: shuffledWords.isEmpty && selectedWords.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
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
                          value: 0.75,
                          backgroundColor: Colors.blueGrey,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(greenPrimary),
                          minHeight: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // SUBTITLE + HINT
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                child: Text(
                  questionEn,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              // SELECTED WORDS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: greenPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: selectedWords.map(
                          (word) {
                        return GestureDetector(
                          onTap: () => _removeWord(word),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: greenPrimary,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "${word['translated']} [${word['en']}]",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.close,
                                    color: Colors.white, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // AVAILABLE WORDS
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minHeight: 200,
                      maxHeight: 200,
                    ),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: shuffledWords.map(
                              (word) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                    color: greenPrimary, width: 2),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () => _selectWord(word),
                                    child: Text(
                                      "${word['translated']} [${word['en']}]",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () =>
                                        _speak(word['translated']!),
                                    child: const Icon(
                                      Icons.volume_up,
                                      color: greenPrimary,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ).toList(),
                      ),
                    ),
                  ),
                ),
              ),

              // CHECK BUTTON
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedWords.length == answerEn.length
                        ? _checkAnswer
                        : null,
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

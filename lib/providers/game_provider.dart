import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../models/question.dart';
import '../services/question_generator.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum GameStatus { idle, countdown, playing, paused, gameOver }

enum AnswerState { none, correct, wrong }

// ─── Provider ─────────────────────────────────────────────────────────────────

class GameProvider extends ChangeNotifier {
  // ── Core State ──────────────────────────────────────────────────────────────
  GameMode _mode = GameMode.classic;
  GameStatus _status = GameStatus.idle;
  AnswerState _lastAnswerState = AnswerState.none;
  int _selectedOptionIndex = -1;

  Question? _currentQuestion;
  int _score = 0;
  int _combo = 0;
  int _maxCombo = 0;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  int _questionsAnswered = 0;
  int _livesRemaining = GameConstants.maxMistakesEndless;
  int _timeRemaining = GameConstants.classicDuration;
  int _countdownValue = 3;
  DateTime? _questionStartTime;

  // ── Difficulty ──────────────────────────────────────────────────────────────
  Difficulty _difficulty = Difficulty.easy;

  // ── Power-Up State ──────────────────────────────────────────────────────────
  bool _isTimeFrozen = false;
  bool _isDoubleScore = false;
  bool _isSlowMotion = false;
  int _hintRemovedOptionIndex = -1;

  final Map<PowerUpType, int> _powerUpInventory = {
    PowerUpType.timeFreeze: 3,
    PowerUpType.doubleScore: 3,
    PowerUpType.hint: 3,
    PowerUpType.autoSolve: 2,
    PowerUpType.slowMotion: 3,
  };

  // ── Timers ──────────────────────────────────────────────────────────────────
  Timer? _gameTimer;
  Timer? _countdownTimer;
  bool _transitioning = false;

  // ── Getters ──────────────────────────────────────────────────────────────────

  GameMode get mode => _mode;
  GameStatus get status => _status;
  AnswerState get lastAnswerState => _lastAnswerState;
  int get selectedOptionIndex => _selectedOptionIndex;

  Question? get currentQuestion => _currentQuestion;
  int get score => _score;
  int get combo => _combo;
  int get maxCombo => _maxCombo;
  int get correctAnswers => _correctAnswers;
  int get wrongAnswers => _wrongAnswers;
  int get questionsAnswered => _questionsAnswered;
  int get livesRemaining => _livesRemaining;
  int get timeRemaining => _timeRemaining;
  int get countdownValue => _countdownValue;
  bool get isTimeFrozen => _isTimeFrozen;
  bool get isDoubleScore => _isDoubleScore;
  bool get isSlowMotion => _isSlowMotion;
  int get hintRemovedOptionIndex => _hintRemovedOptionIndex;
  Map<PowerUpType, int> get powerUpInventory =>
      Map.unmodifiable(_powerUpInventory);
  Difficulty get difficulty => _difficulty;

  bool get isPlaying => _status == GameStatus.playing;
  bool get isGameOver => _status == GameStatus.gameOver;

  double get timerPercent {
    if (_mode == GameMode.zen) return 1.0;
    return (_timeRemaining / GameConstants.classicDuration).clamp(0.0, 1.0);
  }

  double get timeAttackProgress =>
      _questionsAnswered / GameConstants.timeAttackQuestions;

  int get comboMultiplier => min(_combo, GameConstants.comboMaxMultiplier);

  Color get timerColor {
    if (_timeRemaining <= 5) return AppColors.timerDanger;
    if (_timeRemaining <= 15) return AppColors.timerWarning;
    return AppColors.timerNormal;
  }

  // ── Game Lifecycle ───────────────────────────────────────────────────────────

  void startGame(GameMode mode) {
    _mode = mode;
    _reset();
    _startCountdown();
  }

  void _reset() {
    _score = 0;
    _combo = 0;
    _maxCombo = 0;
    _correctAnswers = 0;
    _wrongAnswers = 0;
    _questionsAnswered = 0;
    _difficulty = Difficulty.easy;
    _lastAnswerState = AnswerState.none;
    _selectedOptionIndex = -1;
    _isTimeFrozen = false;
    _isDoubleScore = false;
    _isSlowMotion = false;
    _hintRemovedOptionIndex = -1;
    _transitioning = false;

    _livesRemaining = GameConstants.maxMistakesEndless;
    _timeRemaining = (_mode == GameMode.classic || _mode == GameMode.rush)
        ? GameConstants.classicDuration
        : 0;

    _powerUpInventory.updateAll((_, __) => 3);
    _powerUpInventory[PowerUpType.autoSolve] = 2;

    _gameTimer?.cancel();
    _countdownTimer?.cancel();
  }

  void _startCountdown() {
    _countdownValue = 3;
    _status = GameStatus.countdown;
    notifyListeners();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      _countdownValue--;
      if (_countdownValue <= 0) {
        t.cancel();
        _beginPlaying();
      }
      notifyListeners();
    });
  }

  void _beginPlaying() {
    _status = GameStatus.playing;
    _generateNextQuestion();
    if (_mode != GameMode.zen) _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _gameTimer?.cancel();
    final msInterval = _isSlowMotion ? 2000 : 1000;
    _gameTimer = Timer.periodic(Duration(milliseconds: msInterval), (t) {
      if (_status != GameStatus.playing || _isTimeFrozen) return;
      _timeRemaining--;
      if (_timeRemaining <= 0) {
        t.cancel();
        _endGame();
      }
      notifyListeners();
    });
  }

  void _generateNextQuestion() {
    _hintRemovedOptionIndex = -1;
    _selectedOptionIndex = -1;
    _lastAnswerState = AnswerState.none;
    _questionStartTime = DateTime.now();
    _currentQuestion =
        QuestionGenerator.generate(difficulty: _difficulty);
    notifyListeners();
  }

  // ── Answer Submission ────────────────────────────────────────────────────────

  void submitAnswer(int optionIndex) {
    if (_status != GameStatus.playing ||
        _currentQuestion == null ||
        _transitioning) return;

    final isCorrect =
        _currentQuestion!.options[optionIndex] ==
        _currentQuestion!.correctAnswer;
    final elapsed =
        DateTime.now().difference(_questionStartTime!).inMilliseconds / 1000.0;

    _selectedOptionIndex = optionIndex;
    _lastAnswerState = isCorrect ? AnswerState.correct : AnswerState.wrong;
    _transitioning = true;

    if (isCorrect) {
      _handleCorrect(elapsed);
    } else {
      _handleWrong();
    }

    notifyListeners();

    // Brief delay so player sees the feedback, then advance
    Future.delayed(const Duration(milliseconds: 380), () {
      if (_status != GameStatus.playing) return;
      _questionsAnswered++;
      _adaptDifficulty();

      if (_mode == GameMode.timeAttack &&
          _questionsAnswered >= GameConstants.timeAttackQuestions) {
        _endGame();
        return;
      }
      if (_mode == GameMode.endless && _livesRemaining <= 0) {
        _endGame();
        return;
      }

      _transitioning = false;
      _generateNextQuestion();
    });
  }

  void _handleCorrect(double elapsed) {
    _combo++;
    _correctAnswers++;
    if (_combo > _maxCombo) _maxCombo = _combo;

    int points = GameConstants.baseScore;
    // Streak bonus
    if (_combo > 1) {
      points += GameConstants.streakBonus * min(_combo - 1, 5);
    }
    // Speed bonus (answer in < 2s)
    if (elapsed < 2.0) {
      points += (GameConstants.baseScore * 0.5).round();
    }
    // Double score power-up
    if (_isDoubleScore) points *= 2;
    // Combo multiplier
    points *= comboMultiplier;

    _score += points;

    // Streak time bonus in classic mode
    if ((_mode == GameMode.classic || _mode == GameMode.rush) &&
        _combo > 0 &&
        _combo % 5 == 0) {
      _timeRemaining += 3;
    }
  }

  void _handleWrong() {
    _combo = 0;
    _score = max(0, _score + GameConstants.wrongPenalty);
    if (_mode == GameMode.endless) _livesRemaining--;
  }

  void _adaptDifficulty() {
    if (_questionsAnswered > 0 && _questionsAnswered % 10 == 0) {
      switch (_difficulty) {
        case Difficulty.easy:
          _difficulty = Difficulty.medium;
          break;
        case Difficulty.medium:
          _difficulty = Difficulty.hard;
          break;
        case Difficulty.hard:
          _difficulty = Difficulty.extreme;
          break;
        case Difficulty.extreme:
          break;
      }
    }
  }

  // ── Power-Ups ────────────────────────────────────────────────────────────────

  void activatePowerUp(PowerUpType type) {
    if (_status != GameStatus.playing) return;
    final count = _powerUpInventory[type] ?? 0;
    if (count <= 0) return;

    _powerUpInventory[type] = count - 1;

    switch (type) {
      case PowerUpType.timeFreeze:
        _isTimeFrozen = true;
        Future.delayed(Duration(seconds: GameConstants.timeFreezeSeconds), () {
          _isTimeFrozen = false;
          notifyListeners();
        });
        break;

      case PowerUpType.doubleScore:
        _isDoubleScore = true;
        Future.delayed(Duration(seconds: GameConstants.doubleScoreSeconds), () {
          _isDoubleScore = false;
          notifyListeners();
        });
        break;

      case PowerUpType.hint:
        if (_currentQuestion != null) {
          final wrongIndices = List.generate(
            _currentQuestion!.options.length,
            (i) => i,
          ).where((i) =>
              _currentQuestion!.options[i] != _currentQuestion!.correctAnswer)
              .toList();
          if (wrongIndices.isNotEmpty) {
            wrongIndices.shuffle();
            _hintRemovedOptionIndex = wrongIndices.first;
          }
        }
        break;

      case PowerUpType.autoSolve:
        if (_currentQuestion != null) {
          final correctIdx = _currentQuestion!.correctOptionIndex;
          Future.delayed(const Duration(milliseconds: 300), () {
            submitAnswer(correctIdx);
          });
        }
        break;

      case PowerUpType.slowMotion:
        _isSlowMotion = true;
        _gameTimer?.cancel();
        _startTimer();
        Future.delayed(Duration(seconds: GameConstants.slowMotionSeconds), () {
          _isSlowMotion = false;
          _gameTimer?.cancel();
          _startTimer();
          notifyListeners();
        });
        break;
    }

    notifyListeners();
  }

  // ── Pause / Resume ───────────────────────────────────────────────────────────

  void pauseGame() {
    if (_status != GameStatus.playing) return;
    _status = GameStatus.paused;
    _gameTimer?.cancel();
    notifyListeners();
  }

  void resumeGame() {
    if (_status != GameStatus.paused) return;
    _status = GameStatus.playing;
    if (_mode != GameMode.zen) _startTimer();
    notifyListeners();
  }

  // ── End & Reset ──────────────────────────────────────────────────────────────

  void _endGame() {
    _gameTimer?.cancel();
    _status = GameStatus.gameOver;
    _saveHighScore();
    notifyListeners();
  }

  void resetGame() {
    _gameTimer?.cancel();
    _countdownTimer?.cancel();
    _status = GameStatus.idle;
    notifyListeners();
  }

  GameResult buildResult() {
    final int coinsEarned = _score ~/ 15 + _maxCombo * 2;
    final int xpEarned = _score ~/ 8 + _correctAnswers * 3;
    return GameResult(
      mode: _mode,
      score: _score,
      correctAnswers: _correctAnswers,
      wrongAnswers: _wrongAnswers,
      maxCombo: _maxCombo,
      timeTakenSeconds: GameConstants.classicDuration - _timeRemaining,
      coinsEarned: coinsEarned,
      xpEarned: xpEarned,
      playedAt: DateTime.now(),
    );
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${StorageKeys.highScores}_${_mode.name}';
    final current = prefs.getInt(key) ?? 0;
    if (_score > current) {
      await prefs.setInt(key, _score);
    }
  }

  Future<int> getHighScore(GameMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('${StorageKeys.highScores}_${mode.name}') ?? 0;
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
}

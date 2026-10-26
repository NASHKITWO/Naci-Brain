// lib/providers/game_provider.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/question.dart';
import '../services/question_generator.dart';
import '../utils/constants.dart';

enum GameStatus { idle, countdown, playing, paused, gameOver }

enum AnswerState { none, correct, wrong }

class GameProvider extends ChangeNotifier {
  final Random _rng = Random();

  // ── Core state ──────────────────────────────────────────────────────────────
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
  int _elapsedSeconds = 0;
  int _countdownValue = 3;
  DateTime? _questionStartTime;
  Difficulty _difficulty = Difficulty.easy;

  // ── Power-ups (durations count down in play seconds, so pausing stops them) ─
  int _freezeLeft = 0;
  int _doubleLeft = 0;
  int _slowLeft = 0;
  bool _slowSkip = false;
  int _hintRemovedOptionIndex = -1;

  final Map<PowerUpType, int> _powerUpInventory = {};

  // ── Timers / flags ──────────────────────────────────────────────────────────
  Timer? _ticker;
  Timer? _countdownTimer;
  Timer? _advanceTimer;
  bool _transitioning = false;
  bool _pendingAdvance = false;
  bool _disposed = false;

  GameProvider() {
    _fillInventory();
  }

  // ── Getters ─────────────────────────────────────────────────────────────────
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
  int get elapsedSeconds => _elapsedSeconds;
  int get countdownValue => _countdownValue;
  Difficulty get difficulty => _difficulty;

  bool get isTimeFrozen => _freezeLeft > 0;
  bool get isDoubleScore => _doubleLeft > 0;
  bool get isSlowMotion => _slowLeft > 0;
  int get hintRemovedOptionIndex => _hintRemovedOptionIndex;
  Map<PowerUpType, int> get powerUpInventory =>
      Map.unmodifiable(_powerUpInventory);

  bool get isPlaying => _status == GameStatus.playing;
  bool get isGameOver => _status == GameStatus.gameOver;

  double get timerPercent =>
      (_timeRemaining / GameConstants.classicDuration).clamp(0.0, 1.0);

  double get timeAttackProgress =>
      (_questionsAnswered / GameConstants.timeAttackQuestions).clamp(0.0, 1.0);

  int get comboMultiplier => min(max(_combo, 1), GameConstants.comboMaxMultiplier);

  bool isPowerUpActive(PowerUpType type) {
    switch (type) {
      case PowerUpType.timeFreeze:
        return isTimeFrozen;
      case PowerUpType.doubleScore:
        return isDoubleScore;
      case PowerUpType.slowMotion:
        return isSlowMotion;
      case PowerUpType.hint:
      case PowerUpType.autoSolve:
        return false;
    }
  }

  bool canUsePowerUp(PowerUpType type) {
    final q = _currentQuestion;
    if (_status != GameStatus.playing || _transitioning || q == null) {
      return false;
    }
    if ((_powerUpInventory[type] ?? 0) <= 0) return false;
    switch (type) {
      case PowerUpType.timeFreeze:
        return _mode.hasCountdown && _freezeLeft == 0;
      case PowerUpType.slowMotion:
        return _mode.hasCountdown && _slowLeft == 0;
      case PowerUpType.doubleScore:
        return _doubleLeft == 0;
      case PowerUpType.hint:
        return _hintRemovedOptionIndex == -1 && q.options.length > 2;
      case PowerUpType.autoSolve:
        return true;
    }
  }

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  void startGame(GameMode mode) {
    _mode = mode;
    _reset();
    _startCountdown();
  }

  void _fillInventory() {
    for (final type in PowerUpType.values) {
      _powerUpInventory[type] = type == PowerUpType.autoSolve
          ? GameConstants.autoSolvePerGame
          : GameConstants.powerUpsPerGame;
    }
  }

  void _cancelTimers() {
    _ticker?.cancel();
    _countdownTimer?.cancel();
    _advanceTimer?.cancel();
    _ticker = null;
    _countdownTimer = null;
    _advanceTimer = null;
  }

  void _reset() {
    _cancelTimers();
    _score = 0;
    _combo = 0;
    _maxCombo = 0;
    _correctAnswers = 0;
    _wrongAnswers = 0;
    _questionsAnswered = 0;
    _elapsedSeconds = 0;
    _difficulty = Difficulty.easy;
    _currentQuestion = null;
    _lastAnswerState = AnswerState.none;
    _selectedOptionIndex = -1;
    _freezeLeft = 0;
    _doubleLeft = 0;
    _slowLeft = 0;
    _slowSkip = false;
    _hintRemovedOptionIndex = -1;
    _transitioning = false;
    _pendingAdvance = false;
    _livesRemaining = GameConstants.maxMistakesEndless;
    _timeRemaining =
        _mode.hasCountdown ? GameConstants.classicDuration : 0;
    _fillInventory();
  }

  void _startCountdown() {
    _countdownValue = 3;
    _status = GameStatus.countdown;
    _notify();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      _countdownValue--;
      if (_countdownValue <= 0) {
        t.cancel();
        _beginPlaying();
      } else {
        _notify();
      }
    });
  }

  void _beginPlaying() {
    _status = GameStatus.playing;
    _generateNextQuestion();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
    _notify();
  }

  /// One tick per second of play time. Only classic and rush have a clock to
  /// run down; every other mode just counts elapsed time.
  void _onTick(Timer t) {
    if (_status != GameStatus.playing) return;
    _elapsedSeconds++;

    final frozen = _freezeLeft > 0;
    final slowed = _slowLeft > 0;
    if (frozen) _freezeLeft--;
    if (slowed) _slowLeft--;
    if (_doubleLeft > 0) _doubleLeft--;

    if (_mode.hasCountdown && !frozen) {
      bool drain = true;
      if (slowed) {
        // Slow motion: the clock only drains on every other second.
        _slowSkip = !_slowSkip;
        if (_slowSkip) drain = false;
      }
      if (drain) _timeRemaining--;
      if (_timeRemaining <= 0) {
        _timeRemaining = 0;
        _endGame();
        return;
      }
    }

    if (_mode == GameMode.rush &&
        _elapsedSeconds % GameConstants.rushSpeedInterval == 0) {
      _raiseDifficulty();
    }
    _notify();
  }

  void _generateNextQuestion() {
    _hintRemovedOptionIndex = -1;
    _selectedOptionIndex = -1;
    _lastAnswerState = AnswerState.none;

    Question q = QuestionGenerator.generate(difficulty: _difficulty);
    // Avoid showing the exact same question twice in a row.
    for (int i = 0;
        i < 5 &&
            _currentQuestion != null &&
            q.questionText == _currentQuestion!.questionText;
        i++) {
      q = QuestionGenerator.generate(difficulty: _difficulty);
    }
    _currentQuestion = q;
    _questionStartTime = DateTime.now();
    _notify();
  }

  // ── Answers ─────────────────────────────────────────────────────────────────

  void submitAnswer(int optionIndex, {bool auto = false}) {
    final q = _currentQuestion;
    if (_status != GameStatus.playing || q == null || _transitioning) return;
    if (optionIndex < 0 || optionIndex >= q.options.length) return;
    if (optionIndex == _hintRemovedOptionIndex) return;

    final isCorrect = q.options[optionIndex] == q.correctAnswer;
    final elapsed = _questionStartTime == null
        ? 99.0
        : DateTime.now().difference(_questionStartTime!).inMilliseconds /
            1000.0;

    _selectedOptionIndex = optionIndex;
    _lastAnswerState = isCorrect ? AnswerState.correct : AnswerState.wrong;
    _transitioning = true;
    _questionsAnswered++;

    if (isCorrect) {
      _handleCorrect(auto ? 99.0 : elapsed);
    } else {
      _handleWrong();
    }
    _notify();

    // Brief pause so the player sees the feedback, then move on.
    _advanceTimer?.cancel();
    _advanceTimer = Timer(
      const Duration(milliseconds: GameConstants.answerFeedbackMs),
      _advance,
    );
  }

  void _advance() {
    if (_status == GameStatus.paused) {
      // Paused during the feedback pause: finish the move when resumed.
      _pendingAdvance = true;
      return;
    }
    if (_status != GameStatus.playing) return;
    _pendingAdvance = false;

    if (_mode == GameMode.timeAttack &&
        _questionsAnswered >= GameConstants.timeAttackQuestions) {
      _endGame();
      return;
    }
    if (_mode == GameMode.endless && _livesRemaining <= 0) {
      _endGame();
      return;
    }

    if (_mode != GameMode.rush && _questionsAnswered % 10 == 0) {
      _raiseDifficulty();
    }
    _transitioning = false;
    _generateNextQuestion();
  }

  void _handleCorrect(double elapsed) {
    _combo++;
    _correctAnswers++;
    if (_combo > _maxCombo) _maxCombo = _combo;

    int points = GameConstants.baseScore;
    if (_combo > 1) {
      points += GameConstants.streakBonus * min(_combo - 1, 5);
    }
    if (elapsed < 2.0) points += GameConstants.speedBonus;
    if (_doubleLeft > 0) points *= 2;
    points *= comboMultiplier;
    _score += points;

    // Every 5th correct answer in a row buys a little extra time.
    if (_mode.hasCountdown && _combo % 5 == 0) {
      _timeRemaining += GameConstants.comboTimeBonus;
    }
  }

  void _handleWrong() {
    _combo = 0;
    _wrongAnswers++;
    _score = max(0, _score + GameConstants.wrongPenalty);
    if (_mode == GameMode.endless) _livesRemaining--;
  }

  void _raiseDifficulty() {
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

  // ── Power-ups ───────────────────────────────────────────────────────────────

  void activatePowerUp(PowerUpType type) {
    if (!canUsePowerUp(type)) return;
    final q = _currentQuestion!;
    _powerUpInventory[type] = (_powerUpInventory[type] ?? 0) - 1;

    switch (type) {
      case PowerUpType.timeFreeze:
        _freezeLeft = GameConstants.timeFreezeSeconds;
        break;
      case PowerUpType.doubleScore:
        _doubleLeft = GameConstants.doubleScoreSeconds;
        break;
      case PowerUpType.slowMotion:
        _slowLeft = GameConstants.slowMotionSeconds;
        break;
      case PowerUpType.hint:
        final wrong = <int>[];
        for (int i = 0; i < q.options.length; i++) {
          if (q.options[i] != q.correctAnswer) wrong.add(i);
        }
        if (wrong.isNotEmpty) {
          _hintRemovedOptionIndex = wrong[_rng.nextInt(wrong.length)];
        }
        break;
      case PowerUpType.autoSolve:
        submitAnswer(q.correctOptionIndex, auto: true);
        return; // submitAnswer already notified
    }
    _notify();
  }

  // ── Pause / resume ──────────────────────────────────────────────────────────

  void pauseGame() {
    if (_status != GameStatus.playing) return;
    _status = GameStatus.paused;
    _notify();
  }

  void resumeGame() {
    if (_status != GameStatus.paused) return;
    _status = GameStatus.playing;
    if (_pendingAdvance) _advance();
    _notify();
  }

  // ── End & reset ─────────────────────────────────────────────────────────────

  /// Ends the session and goes to the result screen (used by Zen mode, which
  /// has no natural ending).
  void finishGame() {
    if (_status == GameStatus.playing || _status == GameStatus.paused) {
      _endGame();
    }
  }

  void _endGame() {
    _cancelTimers();
    _status = GameStatus.gameOver;
    _notify();
  }

  /// Stops everything without notifying. Safe to call from a widget's
  /// dispose(), so leaving the screen can never leave a game running.
  void stopSilently() {
    _cancelTimers();
    _transitioning = false;
    _pendingAdvance = false;
    _status = GameStatus.idle;
  }

  GameResult buildResult() {
    return GameResult(
      mode: _mode,
      score: _score,
      correctAnswers: _correctAnswers,
      wrongAnswers: _wrongAnswers,
      maxCombo: _maxCombo,
      timeTakenSeconds: _elapsedSeconds,
    );
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelTimers();
    super.dispose();
  }
}

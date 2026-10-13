/// Main-screen interstitial: the first click, then every third click after that.
class MainScreenClickCounter {
  MainScreenClickCounter._();

  static int _clicks = 0;

  static bool takeAndShouldShow() {
    _clicks += 1;
    return (_clicks - 1) % 3 == 0;
  }
}

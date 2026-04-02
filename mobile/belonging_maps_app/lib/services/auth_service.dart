class AuthService {
  static bool isAdmin = false;

  //temporary login screen
  static Future<bool> login(String username, String password) async {
    if (username == "admin" && password == "1234") {
      isAdmin = true;
      return true;
    }

    isAdmin = false; 
    return false;
  }
}
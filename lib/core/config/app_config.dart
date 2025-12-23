enum Environment {
  development,
  production,
}

class AppConfig {
  static Environment _environment = Environment.development;
  
  static Environment get environment => _environment;
  
  static void setEnvironment(Environment env) {
    _environment = env;
  }
  
  static bool get isDevelopment => _environment == Environment.development;
  static bool get isProduction => _environment == Environment.production;
  
  // Development configuration
  static const String devApiUrl = 'https://dev-api.hardhat.com';
  static const bool devShowDebugInfo = true;
  static const bool devEnableLogging = true;
  
  // Production configuration
  static const String prodApiUrl = 'https://api.hardhat.com';
  static const bool prodShowDebugInfo = false;
  static const bool prodEnableLogging = false;
  
  // Current configuration getters
  static String get apiUrl => isDevelopment ? devApiUrl : prodApiUrl;
  static bool get showDebugInfo => isDevelopment ? devShowDebugInfo : prodShowDebugInfo;
  static bool get enableLogging => isDevelopment ? devEnableLogging : prodEnableLogging;
}
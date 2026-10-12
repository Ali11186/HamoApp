/// إعدادات Nova AI.
/// المفتاح يُمرر وقت البناء ولا يتم تخزينه داخل المستودع.
class GeminiConfig {
  static const String apiKey = String.fromEnvironment('GEMINI_API_KEY');
}

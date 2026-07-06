import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/models/app_settings.dart';

/// AI 对话中的一条消息
class AiMessage {
  final String role; // system / user / assistant
  final String content;
  const AiMessage(this.role, this.content);

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

/// AI 调用异常（业务层据此给友好提示）
class AiException implements Exception {
  final String message;
  AiException(this.message);
  @override
  String toString() => message;
}

/// ============================================================
/// DeepSeek Service —— 独立封装，全 App 复用。
/// DeepSeek 兼容 OpenAI 的 chat/completions 格式。API Key 只存本地。
/// ============================================================
class DeepSeekService {
  final AiConfig config;
  DeepSeekService(this.config);

  bool get isConfigured => config.isConfigured;

  /// 通用对话：返回助手回复的纯文本。
  Future<String> chat(
    List<AiMessage> messages, {
    double temperature = 0.7,
  }) async {
    if (!isConfigured) {
      throw AiException('尚未配置 DeepSeek API Key，请前往「设置」填写。');
    }

    final uri = Uri.parse(config.baseUrl);
    late http.Response resp;
    try {
      resp = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${config.apiKey}',
            },
            body: jsonEncode({
              'model': config.model,
              'messages': messages.map((m) => m.toJson()).toList(),
              'temperature': temperature,
              'stream': false,
            }),
          )
          .timeout(const Duration(seconds: 90));
    } catch (e) {
      throw AiException('网络请求失败：$e\n请检查网络、API 地址是否正确。');
    }

    if (resp.statusCode != 200) {
      final body = utf8.decode(resp.bodyBytes);
      throw AiException('AI 请求出错（${resp.statusCode}）：$body');
    }

    try {
      final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>;
      final content =
          (choices.first as Map<String, dynamic>)['message']['content'];
      return (content as String).trim();
    } catch (e) {
      throw AiException('无法解析 AI 返回内容：$e');
    }
  }

  /// 需要结构化数据的场景：要求 AI 只返回 JSON，并做容错解析。
  /// 返回解析后的 JSON（Map 或 List）。解析失败抛 AiException。
  Future<dynamic> chatJson(
    List<AiMessage> messages, {
    double temperature = 0.4,
  }) async {
    final raw = await chat(messages, temperature: temperature);
    return _extractJson(raw);
  }

  /// 从 AI 文本中鲁棒地抽取 JSON：
  /// 1) 直接解析；2) 去掉 ```json 代码块围栏；3) 截取第一个 { 或 [ 到最后一个 } 或 ]。
  static dynamic _extractJson(String text) {
    String s = text.trim();

    // 去掉 markdown 代码围栏
    if (s.startsWith('```')) {
      s = s.replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '');
      if (s.endsWith('```')) s = s.substring(0, s.length - 3);
      s = s.trim();
    }

    dynamic tryParse(String candidate) {
      try {
        return jsonDecode(candidate);
      } catch (_) {
        return null;
      }
    }

    var parsed = tryParse(s);
    if (parsed != null) return parsed;

    // 截取最外层 JSON（对象或数组）
    final firstObj = s.indexOf('{');
    final firstArr = s.indexOf('[');
    int start;
    String closeChar;
    if (firstArr != -1 && (firstObj == -1 || firstArr < firstObj)) {
      start = firstArr;
      closeChar = ']';
    } else {
      start = firstObj;
      closeChar = '}';
    }
    if (start != -1) {
      final end = s.lastIndexOf(closeChar);
      if (end > start) {
        parsed = tryParse(s.substring(start, end + 1));
        if (parsed != null) return parsed;
      }
    }

    throw AiException('AI 未返回可解析的 JSON。原始内容：\n$text');
  }
}

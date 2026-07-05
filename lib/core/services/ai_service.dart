import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:http/http.dart' as http;

import '../../models/plan_b_result.dart';
import '../../models/user_profile.dart';
import '../../models/workout_routine.dart';

/// Handles all calls to the Manus API using the asynchronous Task architecture.
class AIService {
  AIService._internal();
  static final AIService instance = AIService._internal();

  // Manus Base URL confirmed by documentation
  static const String _baseUrl = 'https://api.manus.im/v2';

  // API key here ⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️
  final String _apiKey = 'Put your API here';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-manus-api-key': _apiKey,
  };

  // ────────────────────────────────────────────────────────────────────────
  // 1. PLAN B  — get biomechanically equivalent alternative
  // ────────────────────────────────────────────────────────────────────────
  Future<PlanBResult> getPlanBAlternative({
    required Exercise busyExercise,
    required List<String> availableEquipment,
    required UserProfile userProfile,
    Uint8List? machineImageBytes,
  }) async {
    final injuryText = userProfile.injuries.isEmpty
        ? 'None reported'
        : userProfile.injuries.join(', ');

    final equipmentText = availableEquipment.isEmpty
        ? 'Bodyweight only'
        : availableEquipment.join(', ');

    // Combined System and User Prompt for Manus
    String fullPrompt = '''
You are PlanB AI — an elite sports scientist and biomechanics expert.
The user's ${busyExercise.name} station is busy. Find the best alternative.
Target muscle group: ${busyExercise.muscleGroup}
Fitness level: ${userProfile.fitnessLevel}
Injury constraints: $injuryText
Available equipment: $equipmentText

CRITICAL RULES:
1. ONLY use available equipment.
2. Treat injuries as HARD constraints.
3. Respond ONLY with a valid JSON object. No markdown, no explanations.

Schema:
{
  "alternative_exercise": "string",
  "target_muscle"       : "string",
  "sets"                : number,
  "reps"                : number,
  "instructions"        : "string (2-3 short cues)",
  "video_search_query"  : "string"
}
''';

    if (machineImageBytes != null) {
      final base64Img = base64Encode(machineImageBytes);
      fullPrompt += '\n\n[Attached Machine Image Base64: $base64Img]\nContext: The above machine is occupied.';
    }
    fullPrompt += '\n\nFINAL CRITICAL INSTRUCTION: You are a REST API. Output ONLY a raw JSON object. Do NOT output any conversational text. DO NOT say "I am analyzing" or "I will find". Start your exact response with { and end with }.';    // Execute the 3-step Manus Flow
    final taskId = await _createTask(fullPrompt);
    await _pollTaskStatus(taskId);
    final rawJson = await _getTaskResult(taskId);

    return PlanBResult.fromJson(_parseJson(rawJson));
  }

  // ────────────────────────────────────────────────────────────────────────
  // 2. AI ROUTINE GENERATOR — personalized routine from user preferences
  // ────────────────────────────────────────────────────────────────────────
  Future<WorkoutRoutine> generateRoutine({
    required String goal,
    required String fitnessLevel,
    required int daysPerWeek,
    required String routineType,
    required List<String> availableEquipment,
    required List<String> injuries,
    String additionalNotes = '',
    String userName = '',
  }) async {
    final injuryText = injuries.isEmpty ? 'None' : injuries.join(', ');
    final equipmentText = availableEquipment.isEmpty
        ? 'Bodyweight only'
        : availableEquipment.join(', ');

    final splitInstruction = routineType == 'AI'
        ? 'Choose the best workout split based on the user\'s goals and available days.'
        : 'Use a $routineType split structure.';

    final fullPrompt = '''
You are PlanB AI — an elite certified personal trainer and exercise scientist.
Generate a complete $daysPerWeek-day workout routine for the user.

USER PROFILE:
- Name: ${userName.isEmpty ? 'Athlete' : userName}
- Goal: $goal
- Fitness Level: $fitnessLevel
- Days per week: $daysPerWeek
- Preferred split: $splitInstruction
- Available equipment: $equipmentText
- Injuries/Constraints: $injuryText
${additionalNotes.isNotEmpty ? '- Additional notes: $additionalNotes' : ''}

CRITICAL RULES:
1. Generate EXACTLY $daysPerWeek workout days.
2. Each day must have 4-6 exercises.
3. ONLY use available equipment.
4. Treat injuries as HARD constraints — never program exercises that stress injured areas.
5. Each exercise must include name, target muscle group, sets, and reps.
6. Respond ONLY with a valid JSON object. No markdown, no explanations, no extra text.

JSON SCHEMA:
{
  "routineName": "string (creative name for the routine)",
  "days": [
    {
      "dayName": "string (e.g. Push Day, Upper Body A, Chest & Triceps)",
      "exercises": [
        {
          "name": "string",
          "muscleGroup": "string",
          "sets": number,
          "reps": number
        }
      ]
    }
  ]
}

FINAL CRITICAL INSTRUCTION: You are a REST API. Output ONLY a raw JSON object. Start your exact response with { and end with }.
''';

    final taskId = await _createTask(fullPrompt);
    await _pollTaskStatus(taskId);
    final rawJson = await _getTaskResult(taskId);

    final parsed = _parseJson(rawJson);
    return WorkoutRoutine.fromJson(parsed);
  }

  // ────────────────────────────────────────────────────────────────────────
  // 2. VISION ROUTINE EXTRACTION
  // ────────────────────────────────────────────────────────────────────────
  Future<List<Exercise>> extractRoutineFromImage(Uint8List imageBytes) async {
    final base64Img = base64Encode(imageBytes);
    final fullPrompt = '''
You are PlanB AI. Extract all exercises from the provided image data.
CRITICAL: Respond with a JSON ARRAY ONLY. No markdown.

Schema:
[{"name":"string","muscleGroup":"string","sets":number,"reps":number}]

[Attached Image Base64: $base64Img]
''';

    final taskId = await _createTask(fullPrompt);
    await _pollTaskStatus(taskId);
    final rawJson = await _getTaskResult(taskId);

    final List<dynamic> list = jsonDecode(_cleanJson(rawJson)) as List;
    return list.map((e) => Exercise.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ────────────────────────────────────────────────────────────────────────
  // Manus API 3-Step Flow Implementations
  // ────────────────────────────────────────────────────────────────────────

  // Step 1: Create Task
  Future<String> _createTask(String prompt) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/task.create'),
      headers: _headers,
      body: jsonEncode({
        'message': {'content': prompt}
      }),
    ).timeout(const Duration(seconds: 15));

    final data = _parseManusResponse(response);
    final taskId = data['task_id'] ?? data['id'] ?? data['taskId'];
    if (taskId == null) throw AIException('Failed to get Task ID from Manus');
    return taskId.toString();
  }

// Step 2: Poll Status
  Future<void> _pollTaskStatus(String taskId) async {
    int attempts = 0;
    const maxAttempts = 30; // 90 seconds max

    while (attempts < maxAttempts) {
      await Future.delayed(const Duration(seconds: 3));

      final response = await http.get(
        Uri.parse('$_baseUrl/task.detail?task_id=$taskId'),
        headers: _headers,
      );

      final data = _parseManusResponse(response);

      final taskObj = data['task'] ?? {};
      final status = (taskObj['status'] ?? data['status'] ?? '').toString().toLowerCase();

      if (status == 'completed' || status == 'done' || status == 'stopped') {
        return;
      } else if (status == 'error' || status == 'failed') {
        throw AIException('Manus Task Failed: Check limits.');
      }
      attempts++;
    }
    throw AIException('Task polling timed out after 90 seconds.');
  }

// Step 3: Fetch Result
  Future<String> _getTaskResult(String taskId) async {
    await Future.delayed(const Duration(seconds: 2));

    final response = await http.get(
      Uri.parse('$_baseUrl/task.listMessages?task_id=$taskId'),
      headers: _headers,
    );

    final data = _parseManusResponse(response);
    final List messages = data['messages'] ?? [];

    if (messages.isEmpty) {
      throw AIException('No messages array! Payload: ${response.body}');
    }

    for (var i = messages.length - 1; i >= 0; i--) {
      final msg = messages[i];
      if (msg['type'] == 'assistant_message') {
        final text = msg['assistant_message']?['content'] ?? '';
        if (text.toString().contains('{') && text.toString().contains('}')) {
          return text.toString();
        }
      }
    }

    for (var i = messages.length - 1; i >= 0; i--) {
      final msg = messages[i];
      if (msg['type'] == 'assistant_message') {
        final text = msg['assistant_message']?['content'] ?? '';
        if (text.toString().isNotEmpty) return text.toString();
      }
    }

    throw AIException('Payload Dump: ${response.body}');
  }
  // ────────────────────────────────────────────────────────────────────────
  // Utilities
  // ────────────────────────────────────────────────────────────────────────

  Map<String, dynamic> _parseManusResponse(http.Response res) {
    if (res.statusCode >= 400 && res.statusCode < 600) {
      throw AIException('HTTP Error ${res.statusCode}: ${res.body}');
    }
    final body = jsonDecode(res.body);
    if (body['ok'] == false) {
      final err = body['error']?['message'] ?? res.body;
      throw AIException('Manus API Error: $err');
    }
    return body['data'] != null ? body['data'] : body;
  }

  Map<String, dynamic> _parseJson(String raw) {
    try {
      String clean = raw.replaceAll('```json', '').replaceAll('```', '').trim();

      final start = clean.indexOf('{');
      final end = clean.lastIndexOf('}');
      if (start != -1 && end != -1) {
        clean = clean.substring(start, end + 1);
      }

      return jsonDecode(clean) as Map<String, dynamic>;
    } catch (e) {
      throw AIException('Failed to parse JSON. Raw AI Output:\n$raw');
    }
  }

  String _cleanJson(String raw) {
    String clean = raw.replaceAll('```json', '').replaceAll('```', '').trim();
    final start = clean.indexOf('[');
    final end = clean.lastIndexOf(']');
    if (start != -1 && end != -1) {
      clean = clean.substring(start, end + 1);
    }
    return clean;
  }
}

class AIException implements Exception {
  final String message;
  const AIException(this.message);
  @override
  String toString() => 'AIException: $message';
}
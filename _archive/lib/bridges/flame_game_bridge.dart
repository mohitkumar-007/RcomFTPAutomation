import 'package:flutter/services.dart';

/// Test-only bridge into the Flame game object via MethodChannel.
/// The app side registers this channel only in debug/profile builds.
/// Channel: com.company.rummy/game_test_bridge
class FlameGameBridge {
  static const _channel = MethodChannel('com.company.rummy/game_test_bridge');

  Future<Map<String, dynamic>> getCurrentGameState() async {
    final result = await _channel.invokeMapMethod<String, dynamic>('getGameState');
    return result ?? {};
  }

  Future<bool> isPlayersTurn() async {
    return await _channel.invokeMethod<bool>('isPlayersTurn') ?? false;
  }

  Future<void> tapCard(String cardId) async {
    await _channel.invokeMethod<void>('tapCard', {'cardId': cardId});
  }

  Future<void> dragCardToDiscard(String cardId) async {
    await _channel.invokeMethod<void>('dragCardToDiscard', {'cardId': cardId});
  }

  Future<void> triggerDrop({bool isFirstDrop = false}) async {
    await _channel.invokeMethod<void>('triggerDrop', {'isFirstDrop': isFirstDrop});
  }

  Future<void> triggerDeclare(List<List<String>> groupedSets) async {
    await _channel.invokeMethod<void>('triggerDeclare', {'sets': groupedSets});
  }

  Future<List<String>> getPlayerHand() async {
    final result = await _channel.invokeListMethod<String>('getPlayerHand');
    return result ?? [];
  }
}

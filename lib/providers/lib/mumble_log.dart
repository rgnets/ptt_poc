import 'dart:collection';

import 'package:loggy/loggy.dart';

enum MumbleLogEntryType { internalEvent, message, userEvent, server, error }

class MumbleLogEntry extends LinkedListEntry<MumbleLogEntry> {
  final MumbleLogEntryType entryType;
  final String message;
  late final DateTime timestamp;

  MumbleLogEntry(this.entryType, this.message) {
    timestamp = DateTime.now();
  }
}

class MumbleLog with UiLoggy {
  LinkedList<MumbleLogEntry> entries = LinkedList<MumbleLogEntry>();
  final int maxEntries;

  MumbleLog({
    this.maxEntries = 1000,
  });

  void addEntry(MumbleLogEntryType type, String message) {
    loggy.info("MumbleLog: $type: $message");
    entries.add(MumbleLogEntry(type, message));
  }

  void message(String message) => addEntry(MumbleLogEntryType.message, message);

  void internal(String message) =>
      addEntry(MumbleLogEntryType.internalEvent, message);

  void user(String message) => addEntry(MumbleLogEntryType.userEvent, message);
  void server(String message) => addEntry(MumbleLogEntryType.server, message);
  void error(String message) => addEntry(MumbleLogEntryType.error, message);
}

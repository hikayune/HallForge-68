import 'dart:typed_data';

const int kWin68HeReportId = 1;
const int kWin68HeReportLength = 63;
const int kCalibrationFamily = 0x21;
const int kCalibrationMarker = 0x18;
const int kCalibrationGroupSize = 22;
const int kCalibrationGroupCount = 6;

enum CalibrationCommandType {
  prepareSession,
  selectKey,
  startSelectedKeys,
  stopSelectedKeys,
  startAnyKey,
  stopAnyKey,
  unknown,
}

enum CalibrationSessionState {
  idle,
  arming,
  running,
  keyCompleted,
  finished,
  aborted,
  timeout,
}

class CalibrationCommand {
  const CalibrationCommand({
    required this.type,
    required this.opcode,
    this.arg0 = 0,
    this.arg1 = 0,
  });

  final CalibrationCommandType type;
  final int opcode;
  final int arg0;
  final int arg1;

  Uint8List toPayload() {
    final payload = Uint8List(kWin68HeReportLength);
    payload[0] = kCalibrationFamily;

    switch (type) {
      case CalibrationCommandType.selectKey:
      case CalibrationCommandType.startSelectedKeys:
      case CalibrationCommandType.stopSelectedKeys:
      case CalibrationCommandType.startAnyKey:
      case CalibrationCommandType.stopAnyKey:
      case CalibrationCommandType.prepareSession:
        payload[4] = kCalibrationMarker;
        payload[5] = opcode;
        payload[6] = arg0;
        payload[7] = arg1;
        return payload;

      case CalibrationCommandType.unknown:
        throw StateError('Cannot build an unknown calibration command.');
    }
  }
}

class CalibrationProgress {
  const CalibrationProgress({
    required this.state,
    required this.mode,
    required this.completedKeyIndices,
    required this.statusCode,
    required this.cancelRequested,
  });

  final CalibrationSessionState state;
  final CalibrationCommandType mode;
  final List<int> completedKeyIndices;
  final int statusCode;
  final bool cancelRequested;

  bool get isAnyKeyMode => mode == CalibrationCommandType.startAnyKey;
}

class CalibrationParseResult {
  const CalibrationParseResult({
    required this.progress,
    required this.newlyCompletedKeyIndices,
  });

  final CalibrationProgress progress;
  final List<int> newlyCompletedKeyIndices;
}

CalibrationCommand calibrationPrepareSession() {
  return const CalibrationCommand(
    type: CalibrationCommandType.prepareSession,
    opcode: 0x03,
  );
}

CalibrationCommand calibrationSelectKeyByIndex(int keyIndex) {
  final group = keyIndex ~/ kCalibrationGroupSize;
  final offset = keyIndex % kCalibrationGroupSize;
  return CalibrationCommand(
    type: CalibrationCommandType.selectKey,
    opcode: 0x07,
    arg0: group,
    arg1: offset,
  );
}

CalibrationCommand calibrationStartSelectedKeys() {
  return const CalibrationCommand(
    type: CalibrationCommandType.startSelectedKeys,
    opcode: 0x08,
    arg0: 0x00,
  );
}

CalibrationCommand calibrationStopSelectedKeys() {
  return const CalibrationCommand(
    type: CalibrationCommandType.stopSelectedKeys,
    opcode: 0x08,
    arg0: 0x01,
  );
}

CalibrationCommand calibrationStartAnyKey() {
  return const CalibrationCommand(
    type: CalibrationCommandType.startAnyKey,
    opcode: 0x0f,
    arg0: 0x00,
  );
}

CalibrationCommand calibrationStopAnyKey() {
  return const CalibrationCommand(
    type: CalibrationCommandType.stopAnyKey,
    opcode: 0x10,
    arg0: 0x00,
  );
}

List<int> decodeCalibrationBitmap(Uint8List payload) {
  if (payload.length < 29) {
    return const <int>[];
  }

  final result = <int>[];
  final bytes = payload.sublist(7, 29);

  for (var byteIndex = 0; byteIndex < bytes.length; byteIndex++) {
    final value = bytes[byteIndex];
    for (var bitIndex = 0; bitIndex < kCalibrationGroupCount; bitIndex++) {
      final isSet = ((value >> bitIndex) & 0x01) == 0x01;
      if (isSet) {
        result.add((kCalibrationGroupSize * bitIndex) + byteIndex);
      }
    }
  }

  return result;
}

CalibrationParseResult? parseCalibrationReport(
  Uint8List payload, {
  List<int> previousCompletedKeyIndices = const <int>[],
  bool cancelRequested = false,
}) {
  if (payload.length < 7 || payload[0] != kCalibrationFamily) {
    return null;
  }

  final opcode = payload[5];
  final status = payload[6];

  if (opcode != 0x08 && opcode != 0x0f) {
    return null;
  }

  final mode = opcode == 0x0f
      ? CalibrationCommandType.startAnyKey
      : CalibrationCommandType.startSelectedKeys;

  if (status == 0x01) {
    final completed = decodeCalibrationBitmap(payload);
    final previous = previousCompletedKeyIndices.toSet();
    final newlyCompleted = completed.where((index) => !previous.contains(index)).toList();

    final state = newlyCompleted.isNotEmpty
        ? CalibrationSessionState.keyCompleted
        : CalibrationSessionState.running;

    return CalibrationParseResult(
      progress: CalibrationProgress(
        state: state,
        mode: mode,
        completedKeyIndices: completed,
        statusCode: status,
        cancelRequested: cancelRequested,
      ),
      newlyCompletedKeyIndices: newlyCompleted,
    );
  }

  if (status == 0x00) {
    return CalibrationParseResult(
      progress: CalibrationProgress(
        state: cancelRequested
            ? CalibrationSessionState.aborted
            : CalibrationSessionState.finished,
        mode: mode,
        completedKeyIndices: List<int>.from(previousCompletedKeyIndices),
        statusCode: status,
        cancelRequested: cancelRequested,
      ),
      newlyCompletedKeyIndices: const <int>[],
    );
  }

  if (status == 0x02 || status == 0x04) {
    return CalibrationParseResult(
      progress: CalibrationProgress(
        state: CalibrationSessionState.aborted,
        mode: mode,
        completedKeyIndices: List<int>.from(previousCompletedKeyIndices),
        statusCode: status,
        cancelRequested: cancelRequested,
      ),
      newlyCompletedKeyIndices: const <int>[],
    );
  }

  return null;
}

import 'dart:io';

import 'package:flutter/services.dart';

const WinHidFilter kWin68HeHidFilter = WinHidFilter(
  vendorId: 0x2e3c,
  usagePage: 0xff1b,
  usage: 0x91,
);

class WinHidFilter {
  const WinHidFilter({
    this.vendorId,
    this.productId,
    this.usagePage,
    this.usage,
  });

  final int? vendorId;
  final int? productId;
  final int? usagePage;
  final int? usage;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (vendorId != null) 'vendorId': vendorId,
      if (productId != null) 'productId': productId,
      if (usagePage != null) 'usagePage': usagePage,
      if (usage != null) 'usage': usage,
    };
  }
}

class WinHidDeviceInfo {
  const WinHidDeviceInfo({
    required this.path,
    required this.vendorId,
    required this.productId,
    required this.usagePage,
    required this.usage,
    required this.inputReportByteLength,
    required this.outputReportByteLength,
    required this.featureReportByteLength,
    required this.productName,
    required this.manufacturerName,
    required this.serialNumber,
  });

  final String path;
  final int vendorId;
  final int productId;
  final int usagePage;
  final int usage;
  final int inputReportByteLength;
  final int outputReportByteLength;
  final int featureReportByteLength;
  final String productName;
  final String manufacturerName;
  final String serialNumber;

  factory WinHidDeviceInfo.fromMap(Map<Object?, Object?> map) {
    return WinHidDeviceInfo(
      path: map['path']! as String,
      vendorId: map['vendorId']! as int,
      productId: map['productId']! as int,
      usagePage: map['usagePage']! as int,
      usage: map['usage']! as int,
      inputReportByteLength: map['inputReportByteLength']! as int,
      outputReportByteLength: map['outputReportByteLength']! as int,
      featureReportByteLength: map['featureReportByteLength']! as int,
      productName: (map['productName'] ?? '') as String,
      manufacturerName: (map['manufacturerName'] ?? '') as String,
      serialNumber: (map['serialNumber'] ?? '') as String,
    );
  }
}

class WinHidInputReport {
  const WinHidInputReport({
    required this.reportId,
    required this.data,
    required this.bytesRead,
  });

  final int reportId;
  final Uint8List data;
  final int bytesRead;

  factory WinHidInputReport.fromMap(Map<Object?, Object?> map) {
    return WinHidInputReport(
      reportId: map['reportId']! as int,
      data: map['data']! as Uint8List,
      bytesRead: map['bytesRead']! as int,
    );
  }
}

class WinHidBridge {
  const WinHidBridge();

  static const MethodChannel _channel = MethodChannel('hallforge68/win_hid');

  Future<List<WinHidDeviceInfo>> enumerateDevices({
    WinHidFilter? filter,
  }) async {
    _ensureWindows();
    final rawDevices = await _channel.invokeListMethod<Object?>(
          'enumerateDevices',
          filter?.toMap(),
        ) ??
        const <Object?>[];

    return rawDevices
        .cast<Map<Object?, Object?>>()
        .map(WinHidDeviceInfo.fromMap)
        .toList(growable: false);
  }

  Future<WinHidDeviceInfo> connect(String path) async {
    _ensureWindows();
    final rawDevice = await _channel.invokeMapMethod<Object?, Object?>(
      'connect',
      <String, Object?>{'path': path},
    );
    if (rawDevice == null) {
      throw StateError('Native HID bridge returned no connected device.');
    }

    return WinHidDeviceInfo.fromMap(rawDevice);
  }

  Future<void> disconnect() async {
    _ensureWindows();
    await _channel.invokeMethod<void>('disconnect');
  }

  Future<bool> isConnected() async {
    _ensureWindows();
    return await _channel.invokeMethod<bool>('isConnected') ?? false;
  }

  Future<WinHidDeviceInfo?> getConnectedDevice() async {
    _ensureWindows();
    final rawDevice = await _channel.invokeMapMethod<Object?, Object?>(
      'getConnectedDevice',
    );
    if (rawDevice == null) {
      return null;
    }

    return WinHidDeviceInfo.fromMap(rawDevice);
  }

  Future<int> writeOutputReport({
    required int reportId,
    required Uint8List data,
  }) async {
    _ensureWindows();
    return await _channel.invokeMethod<int>(
          'writeOutputReport',
          <String, Object?>{
            'reportId': reportId,
            'data': data,
          },
        ) ??
        0;
  }

  Future<WinHidInputReport?> readInputReport({
    Duration timeout = const Duration(milliseconds: 100),
  }) async {
    _ensureWindows();
    final rawReport = await _channel.invokeMapMethod<Object?, Object?>(
      'readInputReport',
      <String, Object?>{'timeoutMs': timeout.inMilliseconds},
    );
    if (rawReport == null) {
      return null;
    }

    return WinHidInputReport.fromMap(rawReport);
  }

  void _ensureWindows() {
    if (!Platform.isWindows) {
      throw UnsupportedError('WinHidBridge is only available on Windows.');
    }
  }
}

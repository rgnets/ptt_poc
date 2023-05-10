import 'dart:io';

import 'package:dumble/dumble.dart';
import 'package:flutter/services.dart';

final ConnectionOptions defaultConnectionOptions = ConnectionOptions(
    host: '192.168.7.15',
    port: 64738,
    name: 'dumble_test',
    password: '',
    pingTimeout: const Duration(seconds: 5));

/// Connect a Mumble server with a user certificate.
/// If you connect with certificate, you can register your self.
/// Instead of passwords, Mumble uses certificates to identify users.
///

Future<ConnectionOptions> createConnectionsOptionsWithCertificate(
    ConnectionOptions connectionOptions) async {
  ByteData certData = await rootBundle.load('assets/dumble_cert.pem');
  ByteData keyData = await rootBundle.load('assets/dumble_key.pem');

  SecurityContext securityContext = SecurityContext.defaultContext;
  // securityContext.setTrustedCertificatesBytes(data.buffer.asUint8List());
  // securityContext..usePrivateKeyBytes(keyData.buffer.asUint8List())..useCertificateChainBytes(certData.buffer.asUint8List());
  return ConnectionOptions(
      host: connectionOptions.host,
      name: connectionOptions.name,
      port: connectionOptions.port,
      password: connectionOptions.password,
      pingTimeout: connectionOptions.pingTimeout,
      incomingAudioStreamTimeout: connectionOptions.incomingAudioStreamTimeout,
      context: SecurityContext(withTrustedRoots: true)
        ..usePrivateKeyBytes(keyData.buffer.asUint8List())
        ..useCertificateChainBytes(certData.buffer.asUint8List()));
}

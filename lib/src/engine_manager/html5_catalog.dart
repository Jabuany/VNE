import 'dart:convert';

import '../engine_api/engine.dart';
import 'runtime_manager.dart';

const html5CatalogVersion = 1;

final class RuntimeCatalogItem {
  const RuntimeCatalogItem({
    required this.package,
    required this.name,
    required this.origin,
    required this.notes,
    this.bundledDescriptor,
  });

  final RuntimePackage package;
  final String name;
  final String origin;
  final String notes;
  final String? bundledDescriptor;

  bool get remote => package.downloadUri.scheme == 'https';
  bool get needsFile => bundledDescriptor == null && !remote;
}

List<RuntimeCatalogItem> html5Catalog(
  RuntimeTarget target, {
  String linuxPackageUrl = '',
}) {
  const descriptor =
      '{"engine":"html5","version":"0.1.0","provider":"android-system-webview"}\n';
  final linux = target.platform == RuntimePlatform.linux;
  if (linux && target.architecture != 'x64') return [];
  if (!linux && !{'arm64', 'arm', 'x64'}.contains(target.architecture)) {
    return [];
  }
  final Uri artifact;
  if (linux && linuxPackageUrl.isNotEmpty) {
    artifact = Uri.parse(linuxPackageUrl);
    if (!isSecureRuntimeUrl(artifact)) {
      throw ArgumentError('El origen del paquete debe ser HTTPS.');
    }
  } else {
    artifact = Uri(
      path: linux ? 'vne-html5-linux-0.1.0.py' : 'html5-android.json',
    );
  }
  final bytes = linux ? 13669 : utf8.encode(descriptor).length;
  return [
    RuntimeCatalogItem(
      package: (
        engineId: 'html5',
        version: '0.1.0',
        api: currentEngineApi,
        target: target,
        downloadUri: artifact,
        sha256: linux
            ? 'ec0c42706f20ea65d620f26e1dd2282c03911cab0c2cb771c183634002c35831'
            : '7fcca5f12a00167c01ebf488ef7aff4933c0838d36bb2896c1082e96ddd44963',
        downloadBytes: bytes,
        installedBytes: bytes,
        license: linux
            ? 'Código de VNE. Licencia de redistribución pendiente.'
            : 'AndroidX WebKit: Apache-2.0. WebView: términos del proveedor.',
      ),
      name: 'HTML5',
      origin: linux
          ? (artifact.hasScheme
                ? artifact.toString()
                : 'Auxiliar local oficial de VNE')
          : 'Adaptador incluido y WebView del sistema Android',
      notes: linux
          ? 'Requiere Debian x64, Wayland, WebKitGTK 4.1, PyGObject y Bubblewrap.'
          : 'Activa el adaptador. El proveedor del sistema conserva sus propias actualizaciones.',
      bundledDescriptor: linux ? null : descriptor,
    ),
  ];
}

bool isSecureRuntimeUrl(Uri uri) =>
    uri.scheme == 'https' &&
    uri.host.isNotEmpty &&
    uri.userInfo.isEmpty &&
    !uri.hasFragment;

import 'package:bluefish/models/author.dart';
import 'package:flutter/foundation.dart';

enum AuthorIdentityKind { euid, puid }

@immutable
class AuthorIdentity {
  final AuthorIdentityKind kind;
  final String id;

  const AuthorIdentity._({required this.kind, required this.id});

  factory AuthorIdentity.euid(String id) {
    return AuthorIdentity._(
      kind: AuthorIdentityKind.euid,
      id: _normalizeExplicitId(id)!,
    );
  }

  factory AuthorIdentity.puid(String id) {
    return AuthorIdentity._(
      kind: AuthorIdentityKind.puid,
      id: _normalizeExplicitId(id)!,
    );
  }

  static AuthorIdentity? fromTyped({String? euid, String? puid}) {
    final normalizedEuid = _normalizeExplicitId(euid);
    final normalizedPuid = _normalizeExplicitId(puid);
    if (normalizedEuid != null && normalizedPuid != null) {
      return null;
    }
    if (normalizedEuid != null) {
      return AuthorIdentity.euid(normalizedEuid);
    }
    if (normalizedPuid != null) {
      return AuthorIdentity.puid(normalizedPuid);
    }
    return null;
  }

  static AuthorIdentity? infer(String? rawId) {
    final normalized = _normalizeExplicitId(rawId);
    if (normalized == null || !_numericPattern.hasMatch(normalized)) {
      return null;
    }

    final int length = normalized.length;
    if (length >= 7 && length <= 9) {
      return AuthorIdentity.puid(normalized);
    }
    if (length >= 13) {
      return AuthorIdentity.euid(normalized);
    }
    return null;
  }

  bool matchesAuthor(Author author) {
    return switch (kind) {
      AuthorIdentityKind.euid => author.euid.trim() == id,
      AuthorIdentityKind.puid => author.puid.trim() == id,
    };
  }

  static final RegExp _numericPattern = RegExp(r'^\d+$');

  static String? _normalizeExplicitId(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  @override
  bool operator ==(Object other) {
    return other is AuthorIdentity && other.kind == kind && other.id == id;
  }

  @override
  int get hashCode => Object.hash(kind, id);

  @override
  String toString() => '${kind.name}:$id';
}

extension AuthorIdentityAuthorX on Author {
  AuthorIdentity? identityOfKind(AuthorIdentityKind kind) {
    return switch (kind) {
      AuthorIdentityKind.euid => AuthorIdentity.fromTyped(euid: euid),
      AuthorIdentityKind.puid => AuthorIdentity.fromTyped(puid: puid),
    };
  }

  AuthorIdentity? preferredIdentity({
    AuthorIdentityKind preferredKind = AuthorIdentityKind.euid,
  }) {
    final preferred = identityOfKind(preferredKind);
    if (preferred != null) {
      return preferred;
    }

    final fallbackKind = preferredKind == AuthorIdentityKind.euid
        ? AuthorIdentityKind.puid
        : AuthorIdentityKind.euid;
    return identityOfKind(fallbackKind);
  }
}

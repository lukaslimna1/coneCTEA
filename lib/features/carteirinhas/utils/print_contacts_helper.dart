enum PrintContactUiState { bothLocked, nameLockedPhoneEditable, bothEditable }

class PrintContactState {
  final PrintContactUiState uiState;

  PrintContactState({required this.uiState});
}

class PrintContactsHelper {
  /// Retorna o estado visual do componente baseado nas regras do Modo Impressão
  static PrintContactState getUiState({
    required String? structuredName,
    required String? structuredPhone,
  }) {
    final hasName = structuredName != null && structuredName.trim().isNotEmpty;
    final hasPhone =
        structuredPhone != null && structuredPhone.trim().isNotEmpty;

    if (hasName && hasPhone) {
      return PrintContactState(
        uiState: PrintContactUiState.bothLocked,
      );
    } else if (hasName && !hasPhone) {
      return PrintContactState(
        uiState: PrintContactUiState.nameLockedPhoneEditable,
      );
    } else {
      return PrintContactState(
        uiState: PrintContactUiState.bothEditable,
      );
    }
  }

  /// Constrói os parâmetros que serão enviados para a RPC (retorna apenas o que for realmente novo)
  static Map<String, String?> buildRpcParams({
    required String? structuredName,
    required String? structuredPhone,
    required String inputName,
    required String inputPhone,
    required bool isIncluded,
  }) {
    final hasName = structuredName != null && structuredName.trim().isNotEmpty;
    final hasPhone =
        structuredPhone != null && structuredPhone.trim().isNotEmpty;

    if (!isIncluded) {
      return {'name': null, 'phone': null};
    }

    final String? newName = (!hasName && inputName.trim().isNotEmpty)
        ? inputName.trim()
        : null;
    final String? newPhone = (!hasPhone && inputPhone.trim().isNotEmpty)
        ? inputPhone.trim()
        : null;

    // Se tenta enviar telefone sem nenhum nome
    if (newPhone != null && !hasName && newName == null) {
      return {'name': null, 'phone': null};
    }

    return {'name': newName, 'phone': newPhone};
  }

  /// Validador puro de formulário
  static String? validateName(
    String? input, {
    required bool isIncluded,
    required String? structuredName,
  }) {
    if (!isIncluded ||
        (structuredName != null && structuredName.trim().isNotEmpty)) {
      return null;
    }
    final name = input?.trim() ?? '';
    if (name.isEmpty) {
      return 'Informe o nome do contato.';
    }
    if (name.length > 100) {
      return 'O nome deve ter no máximo 100 caracteres.';
    }
    return null;
  }

  static String? validatePhone(
    String? input, {
    required bool isIncluded,
    required String? structuredPhone,
  }) {
    if (!isIncluded ||
        (structuredPhone != null && structuredPhone.trim().isNotEmpty)) {
      return null;
    }
    final phone = input?.trim() ?? '';
    if (phone.isEmpty) return null;

    final clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.length < 10 ||
        clean.length > 11 ||
        _isRepeatedPhoneDigits(clean)) {
      return 'Informe um telefone válido com DDD.';
    }
    return null;
  }

  static bool _isRepeatedPhoneDigits(String phone) {
    if (phone.isEmpty) return false;
    return RegExp(r'^(\d)\1+$').hasMatch(phone);
  }
}

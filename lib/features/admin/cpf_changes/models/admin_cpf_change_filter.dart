enum AdminCpfChangeFilter {
  analysis,
  corrections,
  completed,
  confirmation,
  rejected,
  cancelled,
  expiredFailed,
  all,
}

extension AdminCpfChangeFilterExtension on AdminCpfChangeFilter {
  String get technicalKey {
    switch (this) {
      case AdminCpfChangeFilter.analysis:
        return 'analysis';
      case AdminCpfChangeFilter.corrections:
        return 'corrections';
      case AdminCpfChangeFilter.completed:
        return 'completed';
      case AdminCpfChangeFilter.confirmation:
        return 'confirmation';
      case AdminCpfChangeFilter.rejected:
        return 'rejected';
      case AdminCpfChangeFilter.cancelled:
        return 'cancelled';
      case AdminCpfChangeFilter.expiredFailed:
        return 'expired_failed';
      case AdminCpfChangeFilter.all:
        return 'all';
    }
  }
}

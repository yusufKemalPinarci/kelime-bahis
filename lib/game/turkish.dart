String normalizeTr(String input) {
  return input
      .replaceAll('I', 'ı')
      .replaceAll('İ', 'i')
      .toLowerCase()
      .replaceAll('i̇', 'i')
      .trim();
}

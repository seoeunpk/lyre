String? validatePassword(String password) {
  if (password.length < 6) return 'Password must be at least 6 characters.';
  if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(password)) {
    return 'Letters and numbers only.';
  }
  if (!RegExp(r'[a-zA-Z]').hasMatch(password)) {
    return 'Needs at least one letter.';
  }
  if (!RegExp(r'[0-9]').hasMatch(password)) {
    return 'Needs at least one number.';
  }
  return null;
}

String canonicalTimelineName(String name) {
  return switch (name.trim().toLowerCase()) {
    'spotify streaming history' => 'Songs',
    'goodreads reviews' => 'Books',
    'my places' => 'Places',
    _ => name.trim(),
  };
}

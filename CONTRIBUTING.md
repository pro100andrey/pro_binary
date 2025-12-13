# Contributing to pro_binary

Thank you for your interest in contributing! 🎉

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/pro_binary.git`
3. Create a branch: `git checkout -b feature/my-feature`
4. Install dependencies: `dart pub get`

## Development

### Running Tests

```bash
# Run all tests (279+ tests)
dart test

# Run specific test file
dart test test/binary_reader_test.dart
dart test test/binary_writer_test.dart
dart test test/integration_test.dart

# Run with coverage
dart pub global activate coverage
dart pub global run coverage:test_with_coverage
```

### Test Organization

Tests are organized as follows:

- **binary_reader_test.dart**: Unit tests for BinaryReader (190+ tests)
  - Read operations for all data types
  - Boundary conditions and edge cases
  - UTF-8 encoding with special characters
  - Malformed sequence handling
  
- **binary_writer_test.dart**: Unit tests for BinaryWriter (200+ tests)
  - Write operations for all data types
  - Buffer management and expansion
  - Input validation and range checks
  - Float precision and special values
  
- **integration_test.dart**: Integration tests (60+ tests)
  - Complete read-write cycles
  - Round-trip validation
  - Complex data structures
  - String handling (ASCII, Cyrillic, Chinese, emoji)
  - Large data operations
  - Stress tests with nested structures
  
- **Performance tests**: Benchmark measurements
  - binary_reader_performance_test.dart
  - binary_writer_performance_test.dart

### Code Style

```bash
# Format code
dart format .

# Analyze code
dart analyze

# Fix common issues
dart fix --apply
```

### Before Submitting

- [ ] All tests pass (`dart test`)
- [ ] Code is formatted (`dart format .`)
- [ ] No analysis issues (`dart analyze`)
- [ ] Added tests for new features
- [ ] Updated CHANGELOG.md
- [ ] Updated documentation if needed

## Pull Request Process

1. Update the README.md with details of changes if applicable
2. Update the CHANGELOG.md with a note describing your changes
3. Ensure all tests pass and code is properly formatted
4. Submit a pull request with a clear description of changes

## Reporting Bugs

Use the [Bug Report template](.github/ISSUE_TEMPLATE/bug_report.md) and include:

- Clear description of the issue
- Steps to reproduce
- Expected vs actual behavior
- Code sample
- Environment details

## Suggesting Features

Use the [Feature Request template](.github/ISSUE_TEMPLATE/feature_request.md) and describe:

- The feature you'd like
- Your use case
- Proposed API (if applicable)
- Alternative solutions considered

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on what is best for the community

## Questions?

Feel free to open a [Discussion](https://github.com/pro100andrey/pro_binary/discussions) or reach out to maintainers.

Thank you for contributing! 🚀

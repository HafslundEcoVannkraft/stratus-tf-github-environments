# Test Files Documentation

This directory contains YAML test files for validating GitHub environment configurations with different complexity levels and use cases.

## Test Files

### `minimal-github-environments.yaml`

**Purpose**: Tests the absolute minimum required configuration

- Contains only required fields
- Single environment with basic setup
- Used for testing basic functionality and validation
- Ideal for quick smoke tests and CI/CD pipeline validation

**Test Coverage**:

- ✅ Required fields only
- ✅ Basic environment creation
- ✅ Minimal variable configuration

### `comprehensive-github-environments.yaml`

**Purpose**: Tests comprehensive configuration with all available features

- Multiple test scenarios covering different use cases
- All optional fields and advanced configurations
- Edge cases and security-focused scenarios
- Used for thorough integration testing

**Test Coverage**:

- ✅ All configuration options
- ✅ Multiple reviewers (teams + users)
- ✅ Complex deployment policies (branch + tag)
- ✅ Multiple secrets and variables
- ✅ Edge cases (max wait timer)
- ✅ Security configurations
- ✅ Different wait timer values

## Test Scenarios in Comprehensive File

1. **comprehensive-test**: Full-featured environment with all options enabled
2. **max-wait-test**: Edge case testing maximum wait timer (720 seconds)
3. **security-test**: Security-focused configuration with strict policies

## Usage in GitHub Actions Matrix

These files can be used in GitHub Actions matrix strategies:

```yaml
strategy:
  matrix:
    test-file:
      - minimal-github-environments.yaml
      - comprehensive-github-environments.yaml
```

This ensures both minimal and comprehensive configurations are tested in CI/CD pipelines.

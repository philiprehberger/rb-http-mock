# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-04-09

### Added
- `to_raise(exception)` to simulate errors instead of returning a response
- `to_timeout` shorthand that raises `TimeoutError`
- `last_request` for quick access to the most recent recorded request
- Method shortcuts: `stub_get`, `stub_post`, `stub_put`, `stub_patch`, `stub_delete`

## [0.2.1] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.2.0] - 2026-03-29

### Added
- Response sequences via `stub.to_return_in_sequence([...])` for cycling through ordered responses
- Stub verification with `call_count`, `called?`, and `HttpMock.verify!` to detect uncalled stubs
- Callback responses via `stub.to_return { |request| ... }` for dynamic response generation

## [0.1.3] - 2026-03-24

### Fixed
- Remove inline comments from Development section to match template

## [0.1.2] - 2026-03-22

### Changed
- Expanded test coverage to 30+ examples covering edge cases, error paths, and boundary conditions

## [0.1.1] - 2026-03-22

### Changed
- Version bump for republishing

## [0.1.0] - 2026-03-22

### Added
- Initial release
- Fluent stub API with method and URL matching
- Request body and header matching constraints
- Configurable response status, body, and headers
- Request recording for assertions
- Scoped isolation for test cleanup
- Thread-safe stub registry

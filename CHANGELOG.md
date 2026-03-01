# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.1] - 2026-03-01

### Added
- Type-specific methods for defining options: `integer()`, `boolean()`, `number()`, `string()`, and `option()`
- `type` parameter support in `Option` class (`:integer`, `:number`, `:boolean`, `:string`)
- Automatic type conversion based on `type` parameter
- Flexible `number` type that supports both integers and floating-point numbers
- Automatic `-name` flag when `short` and `long` are omitted
- `program_name` and `description` parameters in `Options` constructor
- Automatic `-h`/`--help` support
- Default value support with type-specific defaults when omitted

### Changed
- **BREAKING**: Replaced `convert_to` method with type-specific methods (`integer`, `boolean`, `number`, `string`)
- **BREAKING**: Changed from builder pattern with `convert_to` to declarative type parameter
- `parse!` method renamed to `parse`
- `add` method is now public (was private)
- Default values are now optional for type-specific methods

### Removed
- **BREAKING**: `convert_to` method (replaced by `type` parameter and type-specific methods)

## [0.1.3] - Previous release

### Features
- Basic option parsing with short and long flags
- Validation support
- `convert_to` method for type conversion
- Help display

## [0.1.1] - Initial release

### Features
- Command-line flag parsing
- Short and long option support
- Basic validation

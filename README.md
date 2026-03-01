# simple-cli-options

A small Ruby library for parsing command-line flags (short and long options with values). Inspired by Go's [flag package](https://pkg.go.dev/flag), this library provides a simple, composable approach to CLI option parsing without the complexity of subcommands.

**Note:** This library does **not** support subcommands. It focuses on simple flag parsing for single-command CLI tools.

## Design Philosophy

This library was developed with the goal of **eliminating tight coupling between business logic and presentation layer** that exists in many Ruby CLI frameworks, by using **composition over inheritance**.

Many CLI frameworks require you to inherit from specific classes or use DSLs that define your entire application structure. This creates tight coupling between your business logic and CLI parsing logic, making testing and reuse difficult.

`simple-cli-options` takes a different approach:
- **No inheritance required**: Use it without modifying your existing classes
- **Composition-based**: Instantiate an `Options` object and use it where needed
- **Loose coupling**: Separate CLI parsing logic from business logic
- **Flexible integration**: Easily integrate into existing applications

This makes CLI tool development simpler and more maintainable.

## Version History

See [CHANGELOG.md](CHANGELOG.md) for detailed version history and breaking changes.

**Current version: 0.2.1**

## Installation

**Note:** This project is in **beta**. APIs may change in future releases.

### From a built gem

After building the gem (`gem build simple-cli-options.gemspec` in the repo), install and require:

```bash
gem install simple-cli-options-0.2.1.gem
```

```ruby
require 'simple-cli-options'
# Option and Options are now available
```

### Without a gem (copy or clone)

Use the library as plain Ruby files. No gem packaging or Gemfile required.

1. **Clone or download** the repo, or copy the `lib/` folder (containing `option.rb` and `options.rb`) into your project.
2. **Install the runtime dependency** (needed for type hints):
   ```bash
   gem install sorbet-runtime
   ```
3. **Require the files** from your script (adjust paths if needed):
   ```ruby
   require_relative 'lib/option'
   require_relative 'lib/options'
   ```
   If you keep the library in a subdirectory (e.g. `vendor/simple-options/`):
   ```ruby
   require_relative 'vendor/simple-options/lib/option'
   require_relative 'vendor/simple-options/lib/options'
   ```

A stable gem may be published to RubyGems.org later.

### With Bundler (optional)

If you use a Gemfile, add the dependency and require as above:

```ruby
# Gemfile
gem 'sorbet-runtime'
```

## Quick start

```ruby
require 'simple-cli-options'

# Instantiate an Options object
parser = SimpleOptions::Options.new(
  program_name: 'todo',
  description: 'A simple todo list manager'
)

# Define options using type-specific methods
parser.boolean(:list, desc: 'Show list of todos')
parser.string(:add, desc: 'Add a new todo item')
parser.integer(:delete, desc: 'Delete todo by ID')

# Parse command-line arguments
parser.parse

# Get values
if parser.get(:list)
  puts "Showing todo list..."
elsif parser.get(:add)
  puts "Adding: #{parser.get(:add)}"
elsif parser.get(:delete)
  puts "Deleting todo ##{parser.get(:delete)}"
end
```

**Usage examples:**
```bash
# Show help (automatically supported)
ruby todo.rb -h

# Show list
ruby todo.rb -list

# Add a new task
ruby todo.rb -add "Buy groceries"

# Delete a task
ruby todo.rb -delete 3
```

Specifying `-h` or `--help` automatically displays help and exits.

## API reference

### SimpleOptions::Option

Represents a single option with short form (e.g., `-l`), long form (e.g., `--length`), description, type, validation, and conversion.

#### Constructor

```ruby
Option.new(name, desc:, short: '', long: '', required: false, default: nil, type: :string, **options)
```

- `name` (Symbol): Option name
- `desc` (String): Description (required)
- `short` (String): Short flag form (optional)
- `long` (String): Long flag form (optional)
- `required` (Boolean): Whether the flag is required (default: `false`)
- `default`: Default value (optional)
- `type` (Symbol): Type (`:integer`, `:number`, `:boolean`, `:string`)
- `**options`: Additional options (`:validate`, `:convert`)

**Important:** If both `short` and `long` are omitted, `-name` is automatically used.

#### Attributes

- `#name`, `#short`, `#long`, `#desc`, `#required_flag`, `#type`: Read-only attributes

#### Methods

- `#validate(&block)`: Add a validator (block receives a string, returns `nil` on success or an error message on failure). Returns `self` for chaining.
- `#process(value)`: Run all validators and perform type conversion. Raises `ArgumentError` on validation failure.

**Example:**

```ruby
opt = SimpleOptions::Option.new(:port, desc: 'Port number', type: :integer)
             .validate { |v| (1..65535).cover?(v.to_i) ? nil : 'Port must be between 1 and 65535' }

opt.process('8080')  # => 8080 (Integer)
opt.process('99999') # => raises ArgumentError
```

### SimpleOptions::Options

Collects options, parses command-line arguments, and provides access to parsed values.

#### Constructor

```ruby
Options.new(program_name: nil, description: nil)
```

- `program_name` (String): Program name (defaults to executable name if omitted)
- `description` (String): Program description

#### Type-specific methods (recommended)

Concise methods for defining options:

```ruby
# Integer type
parser.integer(:count, desc: 'Count', short: '', long: '', required: false, default: nil)

# Boolean type
parser.boolean(:verbose, desc: 'Verbose mode', short: '', long: '', required: false, default: nil)

# Number type (integer or float)
parser.number(:ratio, desc: 'Ratio', short: '', long: '', required: false, default: nil)

# String type
parser.string(:name, desc: 'Name', short: '', long: '', required: false, default: nil)

# Generic (type can be specified)
parser.option(:port, desc: 'Port', type: :integer, short: '', long: '', required: false, default: nil)
```

**Omitting default values:**
- When `default` is omitted, type-specific defaults are used:
  - `integer`: `0`
  - `boolean`: `false`
  - `number`: `0`
  - `string`: `''`
  - `option`: `nil`

#### Other methods

- `#add(option)`: Register an `Option` object directly
- `#parse(argv = nil)`: Parse arguments (defaults to `ARGV`). If `-h`/`--help` is present, displays help and exits
- `#get(name)`: Get parsed value (Symbol). Returns default value if flag not specified
- `#show_help`: Display help

#### Automatic support features

1. **`-h` / `--help` support**: Automatically displays help and exits
2. **Unspecified flag handling**: Returns default value (including `nil`)
3. **Error handling**: Displays error message and exits on missing required options or validation failures

## Detailed usage examples

### 1. Basic usage (name and desc only)

When `short` and `long` are omitted, `-name` is automatically used:

```ruby
parser = SimpleOptions::Options.new(
  program_name: 'myapp',
  description: 'My awesome application'
)

# Specify only name and desc
parser.string(:input, desc: 'Input file')
parser.boolean(:verbose, desc: 'Verbose output')

parser.parse
# Can be used like: -input file.txt -verbose
```

### 2. Type support

#### Integer type

```ruby
parser.integer(:port, desc: 'Port number', default: 8080)
parser.parse(%w[-port 3000])
parser.get(:port)  # => 3000 (Integer)
```

#### Number type (flexible numeric support)

The `number` type supports both integers and floating-point numbers:

```ruby
parser.number(:ratio, desc: 'Ratio value')
parser.parse(%w[-ratio 3.14])
parser.get(:ratio)  # => 3.14 (Float)

parser.parse(%w[-ratio 42])
parser.get(:ratio)  # => 42 (Integer when no decimal point)
```

**Number type features:**
- Integer format (`42`) → Converted to `Integer`
- Floating-point format (`3.14`) → Converted to `Float`
- Automatically selects the appropriate type

#### Boolean type

```ruby
parser.boolean(:debug, desc: 'Enable debug mode')

# Accepts the following values
parser.parse(%w[-debug true])   # => true
parser.parse(%w[-debug false])  # => false
parser.parse(%w[-debug yes])    # => true
parser.parse(%w[-debug no])     # => false
parser.parse(%w[-debug 1])      # => true
parser.parse(%w[-debug 0])      # => false

# Defaults to true when value is omitted
parser.parse(%w[-debug])        # => true
```

#### String type

```ruby
parser.string(:name, desc: 'User name', default: 'Guest')
parser.parse(%w[-name Alice])
parser.get(:name)  # => "Alice" (String)
```

### 3. Setting program_name and description

Reflected in help display:

```ruby
parser = SimpleOptions::Options.new(
  program_name: 'mytool',
  description: 'A tool for processing data'
)

parser.string(:file, desc: 'Input file')
parser.show_help
```

**Output:**
```
mytool

A tool for processing data

Usage:
  mytool [flags]

Flags:
  -file                     Input file
```

### 4. Required options and default values

```ruby
parser = SimpleOptions::Options.new(description: 'Data processor')

# Required option
parser.string(:input, desc: 'Input file', required: true)

# Options with default values
parser.integer(:threads, desc: 'Number of threads', default: 4)
parser.string(:output, desc: 'Output file', default: 'output.txt')

parser.parse

# If required option is not specified, displays error message and exits
# Options with default values return the default when not specified
```

### 5. Unspecified flag behavior

```ruby
parser = SimpleOptions::Options.new
parser.integer(:count, desc: 'Count', default: 10)
parser.string(:name, desc: 'Name')  # No default value

parser.parse([])  # No arguments

parser.get(:count)  # => 10 (default value)
parser.get(:name)   # => "" (string type default)
```

### 6. Custom validation

```ruby
parser = SimpleOptions::Options.new
opt = parser.option(:size, desc: 'Size (s/m/l)', type: :string)
opt.validate { |v| %w[s m l].include?(v) ? nil : 'Size must be one of s/m/l' }

parser.parse(%w[-size m])   # OK
parser.parse(%w[-size xl])  # Error: Size must be one of s/m/l
```

### 7. Explicit short and long flag specification

```ruby
parser = SimpleOptions::Options.new

# Specify both short and long
parser.integer(:verbose, desc: 'Verbosity level', short: '-v', long: '--verbose')

# Short only
parser.boolean(:debug, desc: 'Debug mode', short: '-d', long: '')

# Long only
parser.string(:config, desc: 'Config file', short: '', long: '--config')

parser.parse(%w[-v 2 -d --config app.yml])
```

### 8. Automatic help support

```ruby
parser = SimpleOptions::Options.new(
  program_name: 'calculator',
  description: 'Simple calculator'
)
parser.integer(:add, desc: 'Add numbers')
parser.integer(:multiply, desc: 'Multiply numbers')

# When -h or --help is specified, displays help without parsing other options
# Even if required options are missing, displays help without error
parser.parse(%w[-h])  # Displays help and exits
```

## Practical example code

### Todo list manager

Demonstrates the composition pattern:

```ruby
# examples/todo.rb
require 'simple-cli-options'

parser = SimpleOptions::Options.new(
  program_name: 'todo',
  description: 'A simple todo list manager'
)

# Concise definition with only name and desc
parser.boolean(:list, desc: 'Show list of todos')
parser.string(:add, desc: 'Add a new todo item')
parser.integer(:delete, desc: 'Delete todo by ID')

parser.parse

if parser.get(:list)
  # List display logic
elsif parser.get(:add)
  # Add logic
elsif parser.get(:delete)
  # Delete logic
end
```

**Usage examples:**
```bash
ruby examples/todo.rb -h              # Show help
ruby examples/todo.rb -list           # Show todo list
ruby examples/todo.rb -add "Buy milk" # Add new task
ruby examples/todo.rb -delete 3       # Delete task with ID=3
```

### Calculator (demonstrates Number type flexibility)

```ruby
# examples/calculator.rb
parser = SimpleOptions::Options.new(
  program_name: 'calculator',
  description: 'Simple calculator with flexible number support'
)

# Number type supports both integers and floats
parser.number(:add, desc: 'Add two numbers')
parser.number(:multiply, desc: 'Multiply two numbers')
parser.integer(:power, desc: 'Raise to power (integer only)')

parser.parse
```

**Usage examples:**
```bash
ruby examples/calculator.rb -add 3.14      # Float input
ruby examples/calculator.rb -add 42        # Integer input
ruby examples/calculator.rb -multiply 2.5  # Multiplication
ruby examples/calculator.rb -power 2       # Power (integer only)
```

### Additional examples

| File | Description |
|------|-------------|
| [examples/todo.rb](examples/todo.rb) | Todo list manager. Demonstrates concise definition with name and desc only |
| [examples/calculator.rb](examples/calculator.rb) | Calculator. Shows Number type flexibility (integer/float) |
| [examples/paint_calculator.rb](examples/paint_calculator.rb) | Calculate paint amount from room dimensions |
| [examples/greet.rb](examples/greet.rb) | Simple greeting tool |

## Development

### Running tests

Install dependencies, then run RSpec from the project root:

```bash
bundle install
bundle exec rspec spec/
```

### Using test_helper.rb in your own specs

`test_helper.rb` loads RSpec and the library (`option.rb`, `options.rb`), so your specs can use `Option` and `Options` without requiring them yourself.

- **Specs under `spec/`:** use `spec_helper`, which already requires `test_helper`:
  ```ruby
  # spec/my_feature_spec.rb
  require_relative 'spec_helper'

  RSpec.describe Option do
    it 'does something' do
      opt = Option.new(:x, short: '-x', long: '--x', desc: 'X')
      expect(opt.process('value')).to eq 'value'
    end
  end
  ```
- **Specs elsewhere** (e.g. in your app): require `test_helper` by path so the library and RSpec are loaded:
  ```ruby
  require_relative '/path/to/simple-options/test_helper'
  # Now Option, Options are available and RSpec is configured
  ```

Then run your spec with `bundle exec rspec path/to/your_spec.rb`.

### Linting

RuboCop (and rubocop-performance, rubocop-rspec) are in the Gemfile. Run with `bundle exec rubocop`.

## License

MIT (see [LICENSE](LICENSE)).

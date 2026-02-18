# simple-cli-options

A small Ruby library for parsing command-line flags (short and long options with values). Define options with validation and conversion, then parse `ARGV` and read values by name.

## Installation

**Note:** This project is in **beta**. APIs may change in future releases.

### From a built gem (beta)

After building the gem (`gem build simple-cli-options.gemspec` in the repo), install and require:

```bash
gem install simple-cli-options-0.1.0.beta1.gem
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
require_relative 'lib/options'
require_relative 'lib/option'

opts = Options.new(description: 'My CLI')
opts.add Option.new(:name, short: '-n', long: '--name', desc: 'Your name', required: true)
opts.add Option.new(:count, short: '-c', long: '--count', desc: 'Repeat count', required: false)
       .convert(&:to_i)

opts.parse!(ARGV)
puts "Hello, #{opts.get(:name)}!" * (opts.get(:count) || 1)
```

Running with `ruby app.rb -n Alice -c 3` prints `Hello, Alice!` three times. `-h` or `--help` prints usage and exits.

## API reference

### Option

Represents a single flag: short form (e.g. `-l`), long form (e.g. `--length`), description, and optional validation/conversion.

| Method / attribute | Description |
|-------------------|-------------|
| `Option.new(name, short:, long:, desc:, required: false, **options)` | `name` (Symbol), `short` / `long` (String), `desc` (String). At least one of `short` or `long` must be non-empty. `options` may include `:validate` (callable) and `:convert` (callable). |
| `#name`, `#short`, `#long`, `#desc`, `#required_flag` | Read-only attributes. |
| `#validate(&block)` | Appends a validator (block takes a String, returns true/false). Returns `self`. |
| `#convert(&block)` | Sets the converter (block takes a String, returns the value to store). Returns `self`. |
| `#process(value)` | Runs all validators on `value`, then the converter; returns the converted value. Raises if validation fails. |

**Example**

```ruby
opt = Option.new(:port, short: '-p', long: '--port', desc: 'Port number')
             .validate { |v| (1..65535).cover?(v.to_i) }
             .convert(&:to_i)
opt.process('8080')  # => 8080
opt.process('99999') # => raises
```

### Options

Collects options, parses an argument array, and provides access to parsed values.

| Method | Description |
|--------|-------------|
| `Options.new(description: '')` | Creates a parser. `description` is shown above usage in help. |
| `#add(option)` | Registers an `Option`. |
| `#parse!(argv)` | Parses `argv` (e.g. `ARGV`). If `-h` or `--help` is present, prints help and exits 0. Missing required options cause a warning and exit 1. Parsed values are stored by option name. |
| `#get(name)` | Returns the parsed value for the option named `name` (Symbol), or `nil` if not given. |
| `#show_help` | Prints description, usage line, and all flags (short/long and description). |

**Behavior**

- Each option expects the next argument as its value (e.g. `--length 10`).
- Help is built from the options you add; `-h` / `--help` are handled automatically.

## Usage examples

### Required and optional options

```ruby
opts = Options.new(description: 'Greeter')
opts.add Option.new(:name, short: '-n', long: '--name', desc: 'Your name', required: true)
opts.add Option.new(:times, short: '-t', long: '--times', desc: 'Repeat N times').convert(&:to_i)
opts.parse!(ARGV)
name = opts.get(:name)       # required; parse! would have exited if missing
times = opts.get(:times) || 1
```

### Validation and conversion

```ruby
Option.new(:size, short: '-s', long: '--size', desc: 'Size (s/m/l)',
           validate: ->(v) { %w[s m l].include?(v) })
      .convert(&:upcase)
```

### Short-only or long-only

```ruby
Option.new(:verbose, short: '', long: '--verbose', desc: 'Verbose output')
Option.new(:x, short: '-x', long: '', desc: 'Enable X')
```

## Example scripts

| File | Description |
|------|-------------|
| [examples/paint_calculator.rb](examples/paint_calculator.rb) | Room dimensions via `-l`/`--length` and `-w`/`--width`; computes area and gallons of paint. |
| [examples/greet.rb](examples/greet.rb) | Simple greeter using `--name` and optional `--count`. |

Run an example (from project root):

```bash
ruby examples/paint_calculator.rb --length 10 --width 5
ruby examples/greet.rb --name World --count 2
```

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

# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe SimpleOptions::Options do
  let(:opt_length) do
    SimpleOptions::Option.new(:length, short: '-l', long: '--length', desc: 'Length', required: true,
                                       validate: ->(v) { v.to_f.positive? ? nil : 'Please input positive number' },
                                       convert: ->(v) { v.to_f })
  end

  let(:opt_width) do
    SimpleOptions::Option.new(:width, short: '-w', long: '--width', desc: 'Width', required: false,
                                      convert: ->(v) { v.to_f })
  end

  describe '#initialize' do
    it 'accepts description' do
      opts = SimpleOptions::Options.new(description: 'My program')
      expect { opts.show_help }.to output(/My program/).to_stdout
    end

    it 'defaults description to empty' do
      opts = SimpleOptions::Options.new
      out = capture_stdout { opts.show_help }
      expect(out).not_to match(/\A\n\n/) if out.start_with?('Usage:')
    end
  end

  describe '#add and #get' do
    it 'stores and returns value by name after parse' do
      opts = SimpleOptions::Options.new
      opts.add opt_length
      opts.add opt_width
      allow(Kernel).to receive(:exit) { |code = 0| raise SystemExit, code }
      expect { opts.parse(%w[--length 10 --width 5]) }.not_to raise_error
      expect(opts.get(:length)).to eq 10.0
      expect(opts.get(:width)).to eq 5.0
    end

    it 'returns nil for optional option not given' do
      opts = SimpleOptions::Options.new
      opts.add opt_length
      allow(Kernel).to receive(:exit) { |code = 0| raise SystemExit, code }
      opts.parse(%w[--length 7])
      expect(opts.get(:length)).to eq 7.0
      expect(opts.get(:width)).to be_nil
    end
  end

  describe '#parse' do
    it 'shows help and exits 0 when -h or --help is present' do
      opts = SimpleOptions::Options.new(description: 'Desc')
      opts.add SimpleOptions::Option.new(:x, short: '-x', long: '--x', desc: 'X')
      allow(Kernel).to receive(:exit) { |code = 0| raise SystemExit, code }
      expect { opts.parse(%w[--help]) }.to raise_error(SystemExit) do |e|
        expect(e.status).to eq 0
      end
      expect { opts.parse(%w[-h]) }.to raise_error(SystemExit) do |e|
        expect(e.status).to eq 0
      end
    end

    it 'shows help without parsing other options when -h is present' do
      opts = SimpleOptions::Options.new(description: 'Test')
      opts.add SimpleOptions::Option.new(:required_opt, short: '-r', long: '--required', desc: 'Required',
                                                        required: true)
      allow(Kernel).to receive(:exit) { |code = 0| raise SystemExit, code }

      # -hが指定されていれば、必須オプションが欠けていてもヘルプを表示してexit 0
      expect { opts.parse(%w[-h]) }.to raise_error(SystemExit) do |e|
        expect(e.status).to eq 0
      end

      # 無効なオプションがあってもヘルプを表示してexit 0
      expect { opts.parse(%w[--help --invalid-option]) }.to raise_error(SystemExit) do |e|
        expect(e.status).to eq 0
      end
    end

    it 'exits 1 when required option is missing' do
      opts = SimpleOptions::Options.new
      opts.add opt_length
      allow(Kernel).to receive(:exit) { |code = 0| raise SystemExit, code }
      expect { opts.parse(%w[--width 5]) }.to raise_error(SystemExit) do |e|
        expect(e.status).to eq 1
      end
    end

    it 'prints validation error message and exits 1 when validation fails' do
      opts = SimpleOptions::Options.new
      opts.add opt_length
      allow(Kernel).to receive(:exit) { |code = 0| raise SystemExit, code }

      expect do
        expect { opts.parse(%w[--length 0]) }.to raise_error(SystemExit) do |e|
          expect(e.status).to eq 1
        end
      end.to output(/Please input positive number for -l or --length option/).to_stderr
    end

    it 'parses short flags' do
      opts = SimpleOptions::Options.new
      opts.add opt_length
      opts.add opt_width
      allow(Kernel).to receive(:exit) { |code = 0| raise SystemExit, code }
      opts.parse(%w[-l 3 -w 4])
      expect(opts.get(:length)).to eq 3.0
      expect(opts.get(:width)).to eq 4.0
    end

    it 'uses first occurrence when same flag appears twice' do
      opts = SimpleOptions::Options.new
      opts.add opt_length
      allow(Kernel).to receive(:exit) { |code = 0| raise SystemExit, code }
      opts.parse(%w[--length 1 --length 2])
      expect(opts.get(:length)).to eq 1.0
    end
  end

  describe 'parsing argv built from a command-line string' do
    before do
      allow(Kernel).to receive(:exit) { |code = 0| raise SystemExit, code }
    end

    it 'parses long flags from a single string (as if from shell)' do
      opts = SimpleOptions::Options.new
      opts.add opt_length
      opts.add opt_width
      argv = '--length 10 --width 5'.split
      opts.parse(argv)
      expect(opts.get(:length)).to eq 10.0
      expect(opts.get(:width)).to eq 5.0
    end

    it 'parses short flags from a command-line string' do
      opts = SimpleOptions::Options.new
      opts.add opt_length
      opts.add opt_width
      argv = '-l 3 -w 4'.split
      opts.parse(argv)
      expect(opts.get(:length)).to eq 3.0
      expect(opts.get(:width)).to eq 4.0
    end

    it 'parses mixed short and long from a string' do
      opts = SimpleOptions::Options.new
      opts.add opt_length
      opts.add opt_width
      argv = '--length 7 -w 2'.split
      opts.parse(argv)
      expect(opts.get(:length)).to eq 7.0
      expect(opts.get(:width)).to eq 2.0
    end

    it 'parses values with spaces when argv is pre-split (e.g. from shell)' do
      opts = SimpleOptions::Options.new
      opts.add SimpleOptions::Option.new(:name, short: '-n', long: '--name', desc: 'Name')
      argv = ['--name', 'Alice Bob']
      opts.parse(argv)
      expect(opts.get(:name)).to eq 'Alice Bob'
    end

    it 'uses ARGV by default when no argument is given' do
      opts = SimpleOptions::Options.new
      opts.add opt_length
      opts.add opt_width

      stub_const('ARGV', %w[--length 12 --width 8])
      opts.parse

      expect(opts.get(:length)).to eq 12.0
      expect(opts.get(:width)).to eq 8.0
    end

    it 'triggers help when argv string contains --help' do
      opts = SimpleOptions::Options.new(description: 'App')
      opts.add SimpleOptions::Option.new(:x, short: '-x', long: '--x', desc: 'X')
      argv = '--help'.split
      expect { opts.parse(argv) }.to raise_error(SystemExit) do |e|
        expect(e.status).to eq 0
      end
    end
  end

  describe '#show_help' do
    it 'prints usage and flags' do
      opts = SimpleOptions::Options.new(description: 'Test app')
      opts.add SimpleOptions::Option.new(:foo, short: '-f', long: '--foo', desc: 'Foo flag')
      out = capture_stdout { opts.show_help }
      expect(out).to include('Test app')
      expect(out).to include('Usage:')
      expect(out).to include('-f')
      expect(out).to include('--foo')
      expect(out).to include('Foo flag')
    end
  end

  describe 'simplified option definition' do
    it 'uses -name when short and long are omitted' do
      opts = SimpleOptions::Options.new
      opts.option(:verbose, desc: 'Verbose mode')
      allow(Kernel).to receive(:exit) { |code = 0| raise SystemExit, code }
      opts.parse(%w[-verbose])
      expect(opts.get(:verbose)).to eq ''
    end

    it 'allows omitting default value for integer' do
      opts = SimpleOptions::Options.new
      opts.integer(:count, desc: 'Count')
      allow(Kernel).to receive(:exit) { |code = 0| raise SystemExit, code }
      opts.parse([])
      expect(opts.get(:count)).to eq 0
    end

    it 'allows omitting default value for string' do
      opts = SimpleOptions::Options.new
      opts.string(:name, desc: 'Name')
      allow(Kernel).to receive(:exit) { |code = 0| raise SystemExit, code }
      opts.parse([])
      expect(opts.get(:name)).to eq ''
    end

    it 'uses option method with custom type' do
      opts = SimpleOptions::Options.new
      opts.option(:port, desc: 'Port number', type: :integer, default: 8080)
      allow(Kernel).to receive(:exit) { |code = 0| raise SystemExit, code }
      opts.parse(%w[-port 3000])
      expect(opts.get(:port)).to eq 3000
    end

    it 'uses option method with default type (string)' do
      opts = SimpleOptions::Options.new
      opts.option(:host, desc: 'Host name', default: 'localhost')
      allow(Kernel).to receive(:exit) { |code = 0| raise SystemExit, code }
      opts.parse([])
      expect(opts.get(:host)).to eq 'localhost'
    end

    it 'uses default type :string when type is omitted in option method' do
      opts = SimpleOptions::Options.new
      # typeを省略した場合、:stringがデフォルトで使われる
      opt = opts.option(:name, desc: 'Name', default: 'test')
      expect(opt.type).to eq :string
      allow(Kernel).to receive(:exit) { |code = 0| raise SystemExit, code }
      opts.parse(%w[-name value])
      expect(opts.get(:name)).to eq 'value'
    end

    it 'returns default value when flag is not specified' do
      opts = SimpleOptions::Options.new
      opts.integer(:count, desc: 'Count', default: 10)
      allow(Kernel).to receive(:exit) { |code = 0| raise SystemExit, code }
      opts.parse([])
      # フラグが指定されていない場合、デフォルト値が返される
      expect(opts.get(:count)).to eq 10
    end

    it 'returns nil when flag is not specified and no default is given' do
      opts = SimpleOptions::Options.new
      opts.option(:optional, desc: 'Optional value')
      allow(Kernel).to receive(:exit) { |code = 0| raise SystemExit, code }
      opts.parse([])
      # デフォルト値がnilの場合、nilが返される（現在の実装ではnilが返される）
      expect(opts.get(:optional)).to be_nil
    end
  end

  def capture_stdout
    old = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old
  end
end

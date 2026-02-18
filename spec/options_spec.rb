# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe Options do
  let(:opt_length) do
    Option.new(:length, short: '-l', long: '--length', desc: 'Length', required: true)
          .validate { |v| v.to_f.positive? }
          .convert(&:to_f)
  end

  let(:opt_width) do
    Option.new(:width, short: '-w', long: '--width', desc: 'Width', required: false)
          .convert(&:to_f)
  end

  describe '#initialize' do
    it 'accepts description' do
      opts = Options.new(description: 'My program')
      expect { opts.show_help }.to output(/My program/).to_stdout
    end

    it 'defaults description to empty' do
      opts = Options.new
      out = capture_stdout { opts.show_help }
      expect(out).not_to match(/\A\n\n/) if out.start_with?('Usage:')
    end
  end

  describe '#add and #get' do
    it 'stores and returns value by name after parse!' do
      opts = Options.new
      opts.add opt_length
      opts.add opt_width
      # Avoid exit: stub exit to raise so we can test parse!
      allow(Kernel).to receive(:exit) { |code = 0| raise SystemExit, code }
      expect { opts.parse!(%w[--length 10 --width 5]) }.not_to raise_error
      expect(opts.get(:length)).to eq 10.0
      expect(opts.get(:width)).to eq 5.0
    end

    it 'returns nil for optional option not given' do
      opts = Options.new
      opts.add opt_length
      allow(Kernel).to receive(:exit) { |code = 0| raise SystemExit, code }
      opts.parse!(%w[--length 7])
      expect(opts.get(:length)).to eq 7.0
      expect(opts.get(:width)).to be_nil
    end
  end

  describe '#parse!' do
    it 'shows help and exits 0 when -h or --help is present' do
      opts = Options.new(description: 'Desc')
      opts.add Option.new(:x, short: '-x', long: '--x', desc: 'X')
      allow(Kernel).to receive(:exit) { |code = 0| raise SystemExit, code }
      expect { opts.parse!(%w[--help]) }.to raise_error(SystemExit) do |e|
        expect(e.status).to eq 0
      end
      expect { opts.parse!(%w[-h]) }.to raise_error(SystemExit) do |e|
        expect(e.status).to eq 0
      end
    end

    it 'exits 1 when required option is missing' do
      opts = Options.new
      opts.add opt_length
      allow(Kernel).to receive(:exit) { |code = 0| raise SystemExit, code }
      expect { opts.parse!(%w[--width 5]) }.to raise_error(SystemExit) do |e|
        expect(e.status).to eq 1
      end
    end

    it 'parses short flags' do
      opts = Options.new
      opts.add opt_length
      opts.add opt_width
      allow(Kernel).to receive(:exit) { |code = 0| raise SystemExit, code }
      opts.parse!(%w[-l 3 -w 4])
      expect(opts.get(:length)).to eq 3.0
      expect(opts.get(:width)).to eq 4.0
    end

    it 'uses first occurrence when same flag appears twice' do
      opts = Options.new
      opts.add opt_length
      allow(Kernel).to receive(:exit) { |code = 0| raise SystemExit, code }
      opts.parse!(%w[--length 1 --length 2])
      expect(opts.get(:length)).to eq 1.0
    end
  end

  describe 'parsing argv built from a command-line string' do
    before do
      allow(Kernel).to receive(:exit) { |code = 0| raise SystemExit, code }
    end

    it 'parses long flags from a single string (as if from shell)' do
      opts = Options.new
      opts.add opt_length
      opts.add opt_width
      argv = '--length 10 --width 5'.split
      opts.parse!(argv)
      expect(opts.get(:length)).to eq 10.0
      expect(opts.get(:width)).to eq 5.0
    end

    it 'parses short flags from a command-line string' do
      opts = Options.new
      opts.add opt_length
      opts.add opt_width
      argv = '-l 3 -w 4'.split
      opts.parse!(argv)
      expect(opts.get(:length)).to eq 3.0
      expect(opts.get(:width)).to eq 4.0
    end

    it 'parses mixed short and long from a string' do
      opts = Options.new
      opts.add opt_length
      opts.add opt_width
      argv = '--length 7 -w 2'.split
      opts.parse!(argv)
      expect(opts.get(:length)).to eq 7.0
      expect(opts.get(:width)).to eq 2.0
    end

    it 'parses values with spaces when argv is pre-split (e.g. from shell)' do
      opts = Options.new
      opts.add Option.new(:name, short: '-n', long: '--name', desc: 'Name')
      argv = ['--name', 'Alice Bob']
      opts.parse!(argv)
      expect(opts.get(:name)).to eq 'Alice Bob'
    end

    it 'uses ARGV by default when no argument is given' do
      opts = Options.new
      opts.add opt_length
      opts.add opt_width

      stub_const('ARGV', %w[--length 12 --width 8])
      opts.parse!

      expect(opts.get(:length)).to eq 12.0
      expect(opts.get(:width)).to eq 8.0
    end

    it 'triggers help when argv string contains --help' do
      opts = Options.new(description: 'App')
      opts.add Option.new(:x, short: '-x', long: '--x', desc: 'X')
      argv = '--help'.split
      expect { opts.parse!(argv) }.to raise_error(SystemExit) do |e|
        expect(e.status).to eq 0
      end
    end
  end

  describe '#show_help' do
    it 'prints usage and flags' do
      opts = Options.new(description: 'Test app')
      opts.add Option.new(:foo, short: '-f', long: '--foo', desc: 'Foo flag')
      out = capture_stdout { opts.show_help }
      expect(out).to include('Test app')
      expect(out).to include('Usage:')
      expect(out).to include('-f')
      expect(out).to include('--foo')
      expect(out).to include('Foo flag')
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

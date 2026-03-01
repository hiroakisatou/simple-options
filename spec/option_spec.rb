# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe SimpleOptions::Option do
  describe '.new' do
    it 'accepts valid short and long flags' do
      opt = SimpleOptions::Option.new(:foo, short: '-f', long: '--foo', desc: 'Foo option')
      expect(opt.name).to eq :foo
      expect(opt.short).to eq '-f'
      expect(opt.long).to eq '--foo'
      expect(opt.desc).to eq 'Foo option'
      expect(opt.required_flag).to eq false
    end

    it 'accepts required: true' do
      opt = SimpleOptions::Option.new(:bar, short: '-b', long: '--bar', desc: 'Bar', required: true)
      expect(opt.required_flag).to eq true
    end

    it 'allows only short flag' do
      opt = SimpleOptions::Option.new(:x, short: '-x', long: '', desc: 'Short only')
      expect(opt.short).to eq '-x'
      expect(opt.long).to eq ''
    end

    it 'allows only long flag' do
      opt = SimpleOptions::Option.new(:verbose, short: '', long: '--verbose', desc: 'Long only')
      expect(opt.short).to eq ''
      expect(opt.long).to eq '--verbose'
    end

    it 'uses -name when both short and long are omitted' do
      opt = SimpleOptions::Option.new(:count, desc: 'Count option')
      expect(opt.short).to eq '-count'
      expect(opt.long).to eq ''
    end

    it 'raises ArgumentError when name is empty' do
      expect do
        SimpleOptions::Option.new(:'', short: '-x', long: '--x', desc: 'Desc')
      end.to raise_error(ArgumentError, /name.*cannot be empty/)
    end

    it 'raises ArgumentError when desc is empty' do
      expect do
        SimpleOptions::Option.new(:x, short: '-x', long: '--x', desc: '')
      end.to raise_error(ArgumentError, /desc.*cannot be empty/)
    end
  end

  describe '#validate' do
    it 'adds a custom validator and returns self' do
      opt = SimpleOptions::Option.new(:n, short: '-n', long: '--num', desc: 'Number')
                                 .validate { |v| v.to_i.positive? ? nil : 'must be positive' }
      expect(opt.process('42')).to eq '42'
      expect { opt.process('0') }.to raise_error(ArgumentError, /must be positive/)
      expect { opt.process('-1') }.to raise_error(ArgumentError, /must be positive/)
    end
  end

  describe '#process' do
    it 'runs validators then converter' do
      opt = SimpleOptions::Option.new(:size, short: '-s', long: '--size', desc: 'Size',
                                             validate: lambda { |v|
                                               %w[s m l].include?(v) ? nil : 'size must be one of s/m/l'
                                             },
                                             convert: ->(v) { v.upcase })
      expect(opt.process('m')).to eq 'M'
      expect { opt.process('x') }.to raise_error(ArgumentError, %r{size must be one of s/m/l})
    end

    it 'uses :validate option from initialize' do
      opt = SimpleOptions::Option.new(
        :x,
        short: '-x',
        long: '--x',
        desc: 'X',
        validate: ->(v) { v == 'ok' ? nil : 'must be ok' }
      )
      expect(opt.process('ok')).to eq 'ok'
      expect { opt.process('no') }.to raise_error(ArgumentError, /must be ok/)
    end

    it 'returns default value when value is nil' do
      opt = SimpleOptions::Option.new(:x, short: '-x', long: '--x', desc: 'X', default: 'default_value')
      expect(opt.process(nil)).to eq 'default_value'
    end
  end

  describe 'type: :integer' do
    it 'converts string to integer' do
      opt = SimpleOptions::Option.new(:count, short: '-c', long: '--count', desc: 'Count', type: :integer)
      expect(opt.process('42')).to eq 42
      expect(opt.process('-10')).to eq(-10)
      expect(opt.process('0')).to eq 0
    end

    it 'validates integer format' do
      opt = SimpleOptions::Option.new(:count, short: '-c', long: '--count', desc: 'Count', type: :integer)
      expect { opt.process('12.5') }.to raise_error(ArgumentError, /must be an integer/)
      expect { opt.process('abc') }.to raise_error(ArgumentError, /must be an integer/)
    end

    it 'handles edge values' do
      opt = SimpleOptions::Option.new(:num, short: '-n', long: '--num', desc: 'Number', type: :integer)
      expect(opt.process('2147483647')).to eq 2_147_483_647
      expect(opt.process('-2147483648')).to eq(-2_147_483_648)
    end
  end

  describe 'type: :number' do
    it 'converts string to number (integer or float)' do
      opt = SimpleOptions::Option.new(:value, short: '-v', long: '--value', desc: 'Value', type: :number)
      expect(opt.process('42')).to eq 42
      expect(opt.process('3.14')).to eq 3.14
      expect(opt.process('-2.5')).to eq(-2.5)
      expect(opt.process('0')).to eq 0
      expect(opt.process('0.0')).to eq 0
    end

    it 'validates number format' do
      opt = SimpleOptions::Option.new(:value, short: '-v', long: '--value', desc: 'Value', type: :number)
      expect { opt.process('abc') }.to raise_error(ArgumentError, /must be a number/)
      expect { opt.process('12.34.56') }.to raise_error(ArgumentError, /must be a number/)
    end

    it 'handles edge values' do
      opt = SimpleOptions::Option.new(:num, short: '-n', long: '--num', desc: 'Number', type: :number)
      expect(opt.process('999999999999999')).to eq 999_999_999_999_999
      expect(opt.process('-999999999999999')).to eq(-999_999_999_999_999)
      expect(opt.process('0.0000001')).to eq 0.0000001
    end
  end

  describe 'type: :boolean' do
    it 'converts boolean strings' do
      opt = SimpleOptions::Option.new(:flag, short: '-f', long: '--flag', desc: 'Flag', type: :boolean)
      expect(opt.process('true')).to eq true
      expect(opt.process('t')).to eq true
      expect(opt.process('1')).to eq true
      expect(opt.process('yes')).to eq true
      expect(opt.process('y')).to eq true
      expect(opt.process('false')).to eq false
      expect(opt.process('f')).to eq false
      expect(opt.process('0')).to eq false
      expect(opt.process('no')).to eq false
      expect(opt.process('n')).to eq false
    end

    it 'handles case insensitivity' do
      opt = SimpleOptions::Option.new(:flag, short: '-f', long: '--flag', desc: 'Flag', type: :boolean)
      expect(opt.process('TRUE')).to eq true
      expect(opt.process('False')).to eq false
      expect(opt.process('YES')).to eq true
      expect(opt.process('No')).to eq false
    end

    it 'defaults to true for unknown values' do
      opt = SimpleOptions::Option.new(:flag, short: '-f', long: '--flag', desc: 'Flag', type: :boolean)
      expect(opt.process('unknown')).to eq true
    end
  end

  describe 'type: :string (default)' do
    it 'returns string as-is' do
      opt = SimpleOptions::Option.new(:name, short: '-n', long: '--name', desc: 'Name')
      expect(opt.process('hello')).to eq 'hello'
      expect(opt.process('123')).to eq '123'
    end
  end
end

# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe Option do
  describe '.new' do
    it 'accepts valid short and long flags' do
      opt = Option.new(:foo, short: '-f', long: '--foo', desc: 'Foo option')
      expect(opt.name).to eq :foo
      expect(opt.short).to eq '-f'
      expect(opt.long).to eq '--foo'
      expect(opt.desc).to eq 'Foo option'
      expect(opt.required_flag).to eq false
    end

    it 'accepts required: true' do
      opt = Option.new(:bar, short: '-b', long: '--bar', desc: 'Bar', required: true)
      expect(opt.required_flag).to eq true
    end

    it 'allows only short flag' do
      opt = Option.new(:x, short: '-x', long: '', desc: 'Short only')
      expect(opt.short).to eq '-x'
      expect(opt.long).to eq ''
    end

    it 'allows only long flag' do
      opt = Option.new(:verbose, short: '', long: '--verbose', desc: 'Long only')
      expect(opt.short).to eq ''
      expect(opt.long).to eq '--verbose'
    end

    it 'raises ArgumentError when name is empty' do
      expect do
        Option.new(:'', short: '-x', long: '--x', desc: 'Desc')
      end.to raise_error(ArgumentError, /name.*cannot be empty/)
    end

    it 'raises ArgumentError when desc is empty' do
      expect do
        Option.new(:x, short: '-x', long: '--x', desc: '')
      end.to raise_error(ArgumentError, /desc.*cannot be empty/)
    end

    it 'raises ArgumentError when both short and long are empty' do
      expect do
        Option.new(:x, short: '', long: '', desc: 'No flags')
      end.to raise_error(ArgumentError, /At least one of.*short.*long/)
    end
  end

  describe '#validate' do
    it 'adds a custom validator and returns self' do
      opt = Option.new(:n, short: '-n', long: '--num', desc: 'Number')
                   .validate { |v| v.to_i.positive? ? nil : 'must be positive' }
      expect(opt.process('42')).to eq '42'
      expect { opt.process('0') }.to raise_error(ArgumentError, /must be positive/)
      expect { opt.process('-1') }.to raise_error(ArgumentError, /must be positive/)
    end
  end

  describe '#convert' do
    it 'uses custom converter' do
      opt = Option.new(:n, short: '-n', long: '--num', desc: 'Number')
                   .convert(&:to_i)
      expect(opt.process('42')).to eq 42
    end

    it 'overrides default (identity) converter' do
      opt = Option.new(:n, short: '-n', long: '--num', desc: 'Number')
                   .convert { |v| v.to_f * 2 }
      expect(opt.process('21')).to eq 42.0
    end
  end

  describe '#process' do
    it 'runs validators then converter' do
      opt = Option.new(:size, short: '-s', long: '--size', desc: 'Size',
                       validate: ->(v) { %w[s m l].include?(v) ? nil : 'size must be one of s/m/l' })
                   .convert { |v| v.upcase }
      expect(opt.process('m')).to eq 'M'
      expect { opt.process('x') }.to raise_error(ArgumentError, /size must be one of s\/m\/l/)
    end

    it 'uses :validate option from initialize' do
      opt = Option.new(
        :x,
        short: '-x',
        long: '--x',
        desc: 'X',
        validate: ->(v) { v == 'ok' ? nil : 'must be ok' }
      )
      expect(opt.process('ok')).to eq 'ok'
      expect { opt.process('no') }.to raise_error(ArgumentError, /must be ok/)
    end
  end
end

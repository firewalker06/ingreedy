require 'parslet'

require_relative 'amount_parser'
require_relative 'rationalizer'
require_relative 'unit_parser'
require_relative 'unit_variation_mapper'

module Ingreedy

  class Parser < Parslet::Parser

    attr_reader :original_query
    Result = Struct.new(:amount, :unit, :ingredient, :original_query)

    rule(:amount) do
      AmountParser.new.as(:amount)
    end

    rule(:whitespace) do
      match("\s")
    end

    rule(:container_amount) do
      AmountParser.new(key_prefix: 'container')
    end

    rule(:unit) do
      UnitParser.new
    end

    rule(:unit_and_preposition) do
      unit.as(:unit) >> (preposition | whitespace | any.absent?)
    end

    rule(:preposition) do
      if prepositions.empty?
        any
      else
        whitespace >>
        prepositions.map { |con| str(con) }.inject(:|) >>
        whitespace
      end
    end

    rule(:container_unit) do
      UnitParser.new
    end

    rule(:amount_unit_separator) do
      whitespace | str('-')
    end

    rule(:container_size) do
      # e.g. (12 ounce) or 12 ounce
      str('(').maybe >>
      container_amount.as(:container_amount) >>
      amount_unit_separator.maybe >>
      container_unit.as(:unit) >>
      str(')').maybe >> whitespace
    end

    rule(:amount_and_unit) do
      amount >>
      whitespace.maybe >>
      unit_and_preposition.maybe >>
      container_size.maybe
    end

    rule(:standard_format) do
      # (word_digit || number) >> unit_and_preposition >> ingredients
      # e.g. 1/2 (12 oz) can black beans
      amount_and_unit >> any.repeat.as(:ingredient)
    end

    rule(:reverse_format) do
      # e.g. flour 200g
      ((whitespace >> amount_and_unit).absent? >> any).repeat.as(:ingredient) >> whitespace >> amount_and_unit
    end

    rule(:ingredient_addition) do
      standard_format | reverse_format
    end

    root :ingredient_addition

    def initialize(original_query)
      @original_query = original_query
    end

    def parse
      result = Result.new
      result[:original_query] = original_query

      parslet_output = super(original_query)

      result[:amount] = rationalize_total_amount(parslet_output[:amount], parslet_output[:container_amount])

      if parslet_output[:unit]
        result[:unit] = convert_unit_variation_to_canonical(parslet_output[:unit].to_s)
      end

      result[:ingredient] = parslet_output[:ingredient].to_s.lstrip.rstrip #TODO cheating

      result
    end

    private

    def prepositions
      Ingreedy.dictionaries.current.prepositions
    end

    def convert_unit_variation_to_canonical(unit_variation)
      UnitVariationMapper.unit_from_variation(unit_variation)
    end

    def rationalize_total_amount(amount, container_amount)
      if container_amount
        rationalize_amount(amount) * rationalize_amount(container_amount, 'container_')
      else
        rationalize_amount(amount)
      end
    end

    def rationalize_amount(amount, capture_key_prefix = '')
      integer = amount["#{capture_key_prefix}integer_amount".to_sym]
      integer &&= integer.to_s

      float = amount["#{capture_key_prefix}float_amount".to_sym]
      float &&= float.to_s

      fraction = amount["#{capture_key_prefix}fraction_amount".to_sym]
      fraction &&= fraction.to_s

      word = amount["#{capture_key_prefix}word_integer_amount".to_sym]
      word &&= word.to_s

      Rationalizer.rationalize(
        integer:  integer,
        float:    float,
        fraction: fraction,
        word:     word
      )
    end

  end
end

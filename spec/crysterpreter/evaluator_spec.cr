require "../spec_helper"
require "../../src/crysterpreter/evaluator"
require "../../src/crysterpreter/lexer"
require "../../src/crysterpreter/object"
require "../../src/crysterpreter/parser"

record TestExpression(T), input : String, expected : T do
  def self.from(*tests : Tuple(String, T))
    tests.map { |test| new(test[0], test[1]) }
  end
end

alias TestInteger = TestExpression(Int64)
alias TestBoolean = TestExpression(Bool)

module Crysterpreter::Evaluator
  describe Evaluator do
    it "eval integer expression" do
      tests = TestInteger.from(
        {"5", 5_i64},
        {"10", 10_i64},
        {"-5", -5_i64},
        {"-10", -10_i64},
        {"5 + 5 + 5 + 5 - 10", 10_i64},
        {"2 * 2 * 2 * 2 * 2", 32_i64},
        {"-50 + 100 + -50", 0_i64},
        {"5 * 2 + 10", 20_i64},
        {"5 + 2 * 10", 25_i64},
        {"20 + 2 * -10", 0_i64},
        {"50 / 2 * 2 + 10", 60_i64},
        {"2 * (5 + 10)", 30_i64},
        {"3 * 3 * 3 + 10", 37_i64},
        {"3 * (3 * 3) + 10", 37_i64},
        {"(5 + 10 * 2 + 15 / 3) * 2 + -10", 50_i64},
        {"3 / 2 + 3 / 2", 3_i64},
      )

      tests.each do |test|
        evaluated = test_eval(test.input)
        evaluated.should_not be_nil
        if evaluated
          test_integer_object(evaluated, test.expected)
        end
      end
    end

    it "eval boolean expression" do
      tests = TestBoolean.from(
        {"true", true},
        {"false", false},
      )

      tests.each do |test|
        evaluated = test_eval(test.input)
        evaluated.should_not be_nil
        if evaluated
          test_boolean_object(evaluated, test.expected)
        end
      end
    end

    it "bang operator" do
      tests = TestBoolean.from(
        {"!true", false},
        {"!false", true},
        {"!5", false},
        {"!!true", true},
        {"!!false", false},
        {"!!5", true}
      )

      tests.each do |test|
        evaluated = test_eval(test.input)
        evaluated.should_not be_nil
        if evaluated
          test_boolean_object(evaluated, test.expected)
        end
      end
    end
  end
end

def test_eval(input : String) : Crysterpreter::Object::Object?
  l = Crysterpreter::Lexer::Lexer.new(input)
  p = Crysterpreter::Parser::Parser.new(l)
  program = p.parse_program

  Crysterpreter::Evaluator.eval(program)
end

macro define_test_object(object_type, expected_type)
  def test_{{object_type.id.underscore}}_object(object : Crysterpreter::Object::Object, expected : {{expected_type}})
    object.should be_a Crysterpreter::Object::{{object_type}}
    if object.is_a?(Crysterpreter::Object::{{object_type}})
      object.value.should eq expected
    end
  end
end

define_test_object Integer, Int64
define_test_object Boolean, Bool

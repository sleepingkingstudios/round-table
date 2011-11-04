# spec/util/text_processor_spec.rb

require 'spec_helper'
require 'util/text_processor'

module RoundTable::Mock::Util
  class MockTextProcessor
    include RoundTable::Util::TextProcessor
  end # class MockTextProcessor
end # module RoundTable::Mock::Util

describe RoundTable::Util::TextProcessor do
  include RoundTable::Mock::Util
  
  subject { MockTextProcessor.new }
  
  ##################
  # Tokenize Strings
  
  it "can convert a string to an array of tokens" do
    input = "verb object preposition object"
    
    subject.tokenize(input).should eq input.downcase.split.map {|str| str.chomp}
  end # it can convert a string to an array of tokens
  
  it "can convert a token to a boolean" do
    subject.token_to_boolean("y").should be true
    subject.token_to_boolean("yes").should be true
    subject.token_to_boolean("true").should be true
    subject.token_to_boolean("affirmative").should be true
    subject.token_to_boolean("no").should be false
    subject.token_to_boolean("foo").should be false
    subject.token_to_boolean("xyzzy").should be false
  end # it can convert a token to a boolean
  
  it "can break strings into lines with a max character width" do
    length = 80
    text = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do" +
      " eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim" +
      " ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut" +
      " aliquip ex ea commodo consequat. Duis aute irure dolor in" +
      " reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla" +
      " pariatur. Excepteur sint occaecat cupidatat non proident, sunt in" +
      " culpa qui officia deserunt mollit anim id est laborum."
    
    broken_text = subject.break_text(text, length)
    broken_text.should be_a String
    broken_text.gsub(/\-\n/, "").gsub(/\s+/, " ").should eq(text.strip)
    broken_text.split("\n").each do |line|
      line.length.should be <= length
    end # each
    
    length = 10
    text = "The word \"Honorificabilitudinitatibus\" means the state of" +
      " being able to achieve honours."
    broken_text = subject.break_text(text, length)
    broken_text.gsub(/\-\n/, "").gsub(/\s+/, " ").should match(text.strip)
    broken_text.split("\n").each do |line|
      line.length.should be <= length
    end # each
  end # it can break strings into lines with a max character width
end # describe TextProcessor
# spec/events/event_dispatcher_spec.rb

require 'spec_helper'
require 'events/event'
require 'events/event_callback'
require 'events/event_dispatcher'

module RoundTable::Mock
  module Events
    class MockEventDispatcher
      include RoundTable::Events::EventDispatcher
    end # class MockEventDispatcher
    
    class MockEventDispatcherWithBubbling < MockEventDispatcher
      @@foo = :bar
      
      def initialize
        @baz = :bizzle
      end # method initialize
      
      def wibble
        :wobble
      end # method wibble
      
      attr_accessor :parent
    end # class MockEventDispatcherWithBubbling
  end # module Events
end # module RoundTable::Mock

describe RoundTable::Events::EventDispatcher do
  include RoundTable::Events
  include RoundTable::Mock::Events
  
  subject { MockEventDispatcher.new }
  
  before :each do
    @callback = double('mock_callable')
    @callback.stub(:call)
    
    @event = Event.new :event_type
  end # before :each
  
  it "can dispatch events" do
    expect { subject.dispatch_event }.to raise_error ArgumentError
    
    subject.dispatch_event @event
  end # it can dispatch events
  
  it "can add event listeners" do
    expect { subject.add_listener }.to raise_error ArgumentError
    expect { subject.add_listener :event_type }.to raise_error ArgumentError
    expect { subject.add_listener :event_type, nil }.to raise_error ArgumentError
    expect { subject.add_listener :event_type, :symbol }.to raise_error ArgumentError
    expect { subject.add_listener :event_type, "string" }.to raise_error ArgumentError
    
    subject.add_listener :event_type, @callback
  end # it can add event listeners
  
  it "returns an EventCallback on a successfully added listener, or nil on a failure" do
    subject.add_listener(:event_type, @callback).should be_a EventCallback
    subject.add_listener(:event_type, @callback).should be nil
  end # it returns an EventCallback ...
  
  it "passes through custom data to the EventCallback" do
    callback = subject.add_listener(:custom_event, @callback, :foo => :bar)
    callback.data[:event_type].should be :custom_event
    callback.data[:foo].should be :bar
  end # it passes through custom data ...
  
  it "triggers callbacks on dispatched events" do
    subject.add_listener :event_type, @callback
    subject.add_listener :other_type, @callback
    
    @callback.should_receive(:call).with(@event).exactly(1)
    subject.dispatch_event @event
  end # it triggers callbacks on dispatched events
  
  it "can remove event listeners" do
    expect { subject.remove_listener }.to raise_error ArgumentError
    expect { subject.remove_listener :event_type }.to raise_error ArgumentError
    
    other_callback = double('mock_callable')
    other_callback.stub(:call)
    
    subject.add_listener :event_type, @callback
    subject.add_listener :other_type, other_callback
    
    subject.remove_listener :event_type, @callback
    
    @callback.should_not_receive(:call)
    other_callback.should_receive(:call)
    
    subject.dispatch_event @event
    subject.dispatch_event Event.new :other_type
  end # it can remove event listeners
  
  it "can remove event listeners matching a block" do
    other_callback = double('mock_callable')
    other_callback.stub(:call)
    
    subject.add_listener :event_type, @callback
    subject.add_listener :other_type, other_callback
    subject.remove_listeners { |callback| callback.data[:event_type] == :other_type }
    @callback.should_receive(:call)
    other_callback.should_not_receive(:call)
    
    subject.dispatch_event @event
    subject.dispatch_event Event.new :other_type
    
    subject.add_listener :*, @callback, :foo => :bar
    @callback.should_receive(:call)
    subject.dispatch_event Event.new :foo_event
    
    subject.remove_listeners { |callback| callback.data[:foo] == :bar }
    @callback.should_not_receive(:call)
    subject.dispatch_event Event.new :foo_event
  end # it can remove ... matching a block
  
  #########################
  # Generic Event Listeners
  
  it "can add generic listeners which trigger on all events" do
    other_callback = double('callable')
    other_callback.stub(:call)
    
    subject.add_listener :*, @callback
    subject.add_generic_listener other_callback
    
    @callback.should_receive(:call).exactly(2)
    other_callback.should_receive(:call).exactly(2)
    subject.dispatch_event @event
    subject.dispatch_event Event.new :other_type
  end # it can add generic listeners which trigger on all events
  
  it "can remove generic event listeners" do
    other_callback = double('mock_callable')
    other_callback.stub(:call)
    
    subject.add_listener :*, @callback
    subject.add_generic_listener other_callback
    
    subject.remove_generic_listener @callback
    
    @callback.should_not_receive(:call)
    other_callback.should_receive(:call)
    subject.dispatch_event @event
  end # it can remove generic event listeners
  
  ################
  # Event Bubbling
  
  it "can set a bubble parent" do
    parent = MockEventDispatcher.new
    child = MockEventDispatcherWithBubbling.new
    
    child.bubble_parent.should be nil
    
    child.instance_eval {
      self.send :__bubble_attr__=, :@@foo
    } # end instance_eval
    child.bubble_parent.should be :bar
    
    child.instance_eval {
      self.send :__bubble_attr__=, :@baz
    } # end instance_eval
    child.bubble_parent.should be :bizzle
    
    child.instance_eval {
      self.send :__bubble_attr__=, :wibble
    } # end instance_eval
    child.bubble_parent.should be :wobble
  end # it can set a bubble parent
  
  it "can bubble events" do
    parent = MockEventDispatcher.new
    child = MockEventDispatcherWithBubbling.new
    child.parent = parent
    child.bubble_parent.should be parent
    
    callback_has_been_called = false
    callback = Proc.new do |event|
      event.should be @event
      callback_has_been_called = true
      event[:original_dispatcher].should be child
      event[:current_dispatcher].should be parent
    end # proc callback
    
    parent.add_listener :event_type, callback
    @event[:bubbles] = true
    child.dispatch_event @event
    callback_has_been_called.should be true
    
    parent.add_listener :other_type, @callback
    @callback.should_receive(:call).twice
    child.dispatch_event Event.new :other_type, :bubbles => :true
    child.dispatch_event (Event.new :other_type), :bubbles => :true
    
    parent.add_listener :third_type, @callback
    @callback.should_not_receive(:call)
    child.dispatch_event Event.new :third_type
  end # it can bubble events
end # describe EventDispatcher

# frozen_string_literal: true

RSpec.shared_examples 'acting as hash ID' do
  it '#to_param returns a hash id' do
    expect(subject.to_param).to be_an_instance_of String
  end
end

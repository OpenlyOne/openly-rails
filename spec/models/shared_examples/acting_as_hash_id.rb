# frozen_string_literal: true

RSpec.shared_examples 'acting as hash ID' do
  it '#to_param returns a hash id' do
    expect(subject.to_param).to be_an_instance_of String
    expect(subject.to_param).not_to eq subject.id
  end

  it 'responds to .hashids' do
    expect(described_class.hashids).to be_an_instance_of Hashids
  end

  it 'has the correct minimum length' do
    expect(subject.to_param.length).to be >= minimum_length
  end
end

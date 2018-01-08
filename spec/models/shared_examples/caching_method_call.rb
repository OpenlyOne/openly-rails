# frozen_string_literal: true

RSpec.shared_examples 'caching method call' do |method|
  let(:method_name)   { method }
  let(:variable_name) { "@#{method}".to_sym }

  it 'caches output of method for repeat calls' do
    subject.send(method_name)
    expect(subject.instance_variable_get(variable_name)).to be_present
    subject.instance_variable_set(variable_name, 'cached')
    expect(subject.send(method_name)).to eq 'cached'
  end
end

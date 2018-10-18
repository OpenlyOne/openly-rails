# frozen_string_literal: true

RSpec.shared_context 'skip project archive setup' do
  before { allow_any_instance_of(Project::Archive).to receive(:setup) }
end

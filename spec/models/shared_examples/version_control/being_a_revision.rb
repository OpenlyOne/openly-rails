# frozen_string_literal: true

RSpec.shared_examples 'being a revision' do
  describe 'attributes' do
    it { is_expected.to respond_to(:repository) }
  end

  describe 'delegations' do
    it 'delegates lock to repository' do
      expect_any_instance_of(VersionControl::Repository).to receive :lock
      subject.send :lock
    end
  end
end

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

  describe '#diff(revision)' do
    let(:method)    { subject.diff(revision) }
    let(:revision)  { instance_double(VersionControl::Revision) }

    it { expect(method).to be_an_instance_of VersionControl::RevisionDiff }

    it 'sets base to self' do
      expect(method.base).to be subject
    end

    it 'sets differentiator to revision' do
      expect(method.differentiator).to be revision
    end
  end
end

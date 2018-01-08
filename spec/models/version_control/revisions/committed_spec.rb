# frozen_string_literal: true

require 'models/shared_examples/version_control/being_a_revision.rb'
require 'models/shared_examples/version_control/repository_locking.rb'

RSpec.describe VersionControl::Revisions::Committed, type: :model do
  subject(:revision)  { create :revision }
  let(:repository)    { revision.repository }

  it_should_behave_like 'being a revision' do
    subject!(:revision) { create :revision }
  end

  describe 'attributes' do
    it { is_expected.to respond_to(:revision_collection) }
    it { is_expected.to respond_to(:id) }
  end

  describe 'delegations' do
    it 'delegates repository to revision_collection' do
      subject
      expect_any_instance_of(VersionControl::RevisionCollection)
        .to receive :repository
      subject.repository
    end

    it 'delegates tree to @commit' do
      subject
      expect_any_instance_of(Rugged::Commit).to receive :tree
      subject.tree
    end
  end

  describe '#files' do
    subject(:method) { revision.files }
    it do
      is_expected
        .to be_an_instance_of VersionControl::FileCollections::Committed
    end
  end
end

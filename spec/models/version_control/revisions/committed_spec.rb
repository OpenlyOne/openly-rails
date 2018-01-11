# frozen_string_literal: true

require 'models/shared_examples/caching_method_call.rb'
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

  describe '#author_email', isolated_unit_test: true do
    subject(:method)  { revision.author_email }
    let(:revision)    { VersionControl::Revisions::Committed.new(nil, commit) }
    let(:commit)      { instance_double Rugged::Commit }
    let(:author)      { { name: 'alice', email: '123', time: Time.zone.now } }

    before do
      allow(commit).to receive(:oid)
      allow(commit).to receive(:author).and_return author
    end

    it { is_expected.to eq '123' }
  end

  describe '#created_at', isolated_unit_test: true do
    subject(:method)  { revision.created_at }
    let(:revision)    { VersionControl::Revisions::Committed.new(nil, commit) }
    let(:commit)      { instance_double Rugged::Commit }
    let(:author)      { { name: 'alice', email: '123', time: time } }
    let(:time)        { Time.new(2009, 11, 17) }

    before do
      allow(commit).to receive(:oid)
      allow(commit).to receive(:author).and_return author
    end

    it { is_expected.to eq time }
  end

  describe '#files' do
    subject(:method) { revision.files }
    it do
      is_expected
        .to be_an_instance_of VersionControl::FileCollections::Committed
    end
  end

  describe '#summary', isolated_unit_test: true do
    subject(:method)  { revision.summary }
    let(:revision)    { VersionControl::Revisions::Committed.new(nil, commit) }
    let(:commit)      { instance_double Rugged::Commit }
    let(:message)     { 'My Commit Title' }

    before do
      allow(commit).to receive(:oid)
      allow(commit).to receive(:message).and_return message
    end

    it { is_expected.to eq nil }

    context 'when message consist of title and summary' do
      let(:message) { "Initial Commit\r\n\r\nCommit Summary" }

      it 'returns just the summary' do
        is_expected.to eq 'Commit Summary'
      end

      it_behaves_like 'caching method call', :summary do
        subject { revision }
      end
    end

    context 'when message has multiple double line breaks' do
      let(:message) { "Commit Title\r\n\r\nCommit Summary\r\n\r\nOther" }

      it 'returns all the content after the first double line break' do
        is_expected.to eq "Commit Summary\r\n\r\nOther"
      end
    end
  end

  describe '#title', isolated_unit_test: true do
    subject(:method)  { revision.title }
    let(:revision)    { VersionControl::Revisions::Committed.new(nil, commit) }
    let(:commit)      { instance_double Rugged::Commit }
    let(:message)     { 'My Commit Title' }

    before do
      allow(commit).to receive(:oid)
      allow(commit).to receive(:message).and_return message
    end

    it { is_expected.to eq 'My Commit Title' }

    it_behaves_like 'caching method call', :title do
      subject { revision }
    end

    context 'when message consist of title and summary' do
      let(:message) { "Initial Commit\r\n\r\nCommit Summary" }

      it 'returns just the title' do
        is_expected.to eq 'Initial Commit'
      end
    end

    context 'when message has multiple double line breaks' do
      let(:message) { "Commit Title\r\n\r\nCommit Summary\r\n\r\nOther" }

      it 'returns just the content before the first double line break' do
        is_expected.to eq 'Commit Title'
      end
    end
  end
end

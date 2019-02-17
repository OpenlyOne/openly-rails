# frozen_string_literal: true

require 'models/shared_examples/being_notifying.rb'

RSpec.describe VCS::Commit, type: :model do
  subject(:commit) { build_stubbed :vcs_commit }

  it_should_behave_like 'being notifying' do
    let(:notifying) { commit }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:branch).dependent(false) }
    it do
      is_expected.to have_one(:repository).through(:branch).dependent(false)
    end
    it do
      is_expected
        .to belong_to(:parent)
        .class_name('VCS::Commit')
        .autosave(false)
        .dependent(false)
        .optional
    end
    it do
      is_expected
        .to belong_to(:author).class_name('Profiles::User').dependent(false)
    end
    it do
      is_expected
        .to have_many(:children)
        .class_name('VCS::Commit')
        .with_foreign_key(:parent_id)
        .dependent(:destroy)
    end

    it { is_expected.to have_many(:committed_files).dependent(:delete_all) }
    it do
      is_expected
        .to have_many(:committed_versions)
        .class_name('VCS::Version')
        .through(:committed_files)
        .source(:version)
    end
    it do
      is_expected
        .to have_many(:file_diffs).inverse_of(:commit).dependent(:delete_all)
    end
  end

  describe 'attributes' do
    it { is_expected.to have_readonly_attribute(:parent_id) }
  end

  describe 'callbacks' do
    let(:commit) { build :vcs_commit }
    context 'on saving' do
      before do
        allow(commit).to receive(:publishing?).and_return is_publishing
        allow(commit).to receive(:update_files_in_branch)
        allow(commit).to receive(:branch_update_uncaptured_changes_count)
        allow(commit).to receive(:project_touch_captured_at)
        commit.save
      end

      context 'when publishing' do
        let(:is_publishing) { true }

        it { is_expected.to have_received(:update_files_in_branch) }
        it do
          is_expected.to have_received(:branch_update_uncaptured_changes_count)
        end
        it { is_expected.to have_received(:project_touch_captured_at) }
      end

      context 'when not publishing' do
        let(:is_publishing) { false }

        it { is_expected.not_to have_received(:update_files_in_branch) }
        it do
          is_expected
            .not_to have_received(:branch_update_uncaptured_changes_count)
        end
        it { is_expected.not_to have_received(:project_touch_captured_at) }
      end
    end
  end

  describe 'delegations' do
    it do
      is_expected
        .to delegate_method(:update_uncaptured_changes_count)
        .to(:branch)
        .with_prefix
    end
    it do
      is_expected
        .to delegate_method(:touch_captured_at)
        .to(:project)
        .with_prefix
        .allow_nil
    end
  end

  describe 'validations' do
    it { is_expected.not_to validate_presence_of(:title) }

    context 'when is_published=true' do
      before  { commit.is_published = true }
      it      { is_expected.to validate_presence_of(:title) }
      it      { is_expected.not_to validate_presence_of(:summary) }
    end
  end

  describe '.create_draft_and_commit_files_for_branch!(branch, author)' do
    subject(:create_draft) do
      described_class.create_draft_and_commit_files_for_branch!(branch, author)
    end
    let(:draft)   { instance_double VCS::Commit }
    let(:branch)  { instance_double VCS::Branch }
    let(:author)  { instance_double Profiles::User }
    let(:commits) { %w[rev1 rev2 rev3] }

    before do
      allow(described_class).to receive(:create!).and_return(draft)
      allow(draft).to receive(:commit_all_files_in_branch)
      allow(draft).to receive(:generate_diffs)
      allow(branch).to receive(:commits).and_return commits
    end

    after { create_draft }

    it { is_expected.to eq draft }

    it 'calls create! with project, last commit, and author' do
      expect(described_class).to receive(:create!).with(
        branch: branch, parent: 'rev3', author: author
      )
    end

    it { expect(draft).to receive(:commit_all_files_in_branch) }
  end

  describe '#commit_all_files_in_branch' do
    subject(:commit_files)  { commit.commit_all_files_in_branch }
    let(:query)             { class_double ActiveRecord::Relation }

    before do
      allow(VCS::CommittedFile).to receive(:insert_from_select_query)
      collection_proxy = class_double VCS::FileInBranch
      allow(commit.branch)
        .to receive_message_chain(
          :versions_in_branch,
          :without_root
        ).and_return collection_proxy
      allow(collection_proxy)
        .to receive(:select)
        .with('r', :id)
        .and_return query
      allow(commit).to receive(:id).and_return 'r'
    end

    it 'calls CommittedFile.insert_from_select_query' do
      expect(VCS::CommittedFile)
        .to receive(:insert_from_select_query)
        .with(%i[commit_id version_id], query)
      commit_files
    end
  end

  describe '#file_changes' do
    subject { commit.file_changes }

    before do
      diff1 = instance_double VCS::FileDiff
      diff2 = instance_double VCS::FileDiff
      allow(commit).to receive(:file_diffs).and_return [diff1, diff2]
      allow(diff1).to receive(:changes).and_return %w[c1 c2]
      allow(diff2).to receive(:changes).and_return %w[c3]
    end

    it { is_expected.to eq %w[c1 c2 c3] }
  end

  describe '#generate_diffs' do
    subject(:generate_diffs) { commit.generate_diffs }
    let(:calculator) { instance_double VCS::Operations::FileDiffsCalculator }

    before do
      allow(VCS::FileDiff).to receive_message_chain(:where, :delete_all)
      allow(VCS::Operations::FileDiffsCalculator)
        .to receive_message_chain(:new, :cache_diffs!)
    end

    it { is_expected.to be true }

    it 'deletes all file diffs' do
      chain = class_double VCS::FileDiff
      expect(VCS::FileDiff)
        .to receive(:where).with(commit: commit).and_return chain
      expect(chain).to receive(:delete_all)
      subject
    end

    it 'calls VCS::Operations::FileDiffsCalculator#cache_diffs!' do
      expect(VCS::Operations::FileDiffsCalculator)
        .to receive(:new).with(commit: commit).and_return calculator
      expect(calculator).to receive(:cache_diffs!)
      subject
    end

    it 'resets file_diffs association' do
      expect(commit.file_diffs).to receive(:reset)
      subject
    end
  end

  describe '#publish(attributes_to_update)' do
    subject { commit.publish(attribute: 'update') }

    before do
      allow(commit)
        .to receive(:update)
        .with(attribute: 'update', is_published: true)
        .and_return 'return-value-of-update'
    end

    it 'returns the return value of #update' do
      is_expected.to eq 'return-value-of-update'
    end
  end

  describe '#published?' do
    before do
      allow(commit).to receive(:is_published_in_database).and_return published
    end

    context 'when published in database' do
      let(:published) { true }
      it { is_expected.to be_published }
    end

    context 'when not published in database' do
      let(:published) { false }
      it { is_expected.not_to be_published }
    end
  end

  describe '#selected_file_change_ids=(ids)' do
    let(:change1) { instance_double VCS::FileDiff::Change }
    let(:change2) { instance_double VCS::FileDiff::Change }
    let(:change3) { instance_double VCS::FileDiff::Change }

    before do
      allow(commit)
        .to receive(:file_changes).and_return [change1, change2, change3]
      allow(change1).to receive(:id).and_return 'change1'
      allow(change2).to receive(:id).and_return 'change2'
      allow(change3).to receive(:id).and_return 'change3'
    end

    after { commit.selected_file_change_ids = %w[change1 change3] }

    it 'selects change1, change3 and unselects change2' do
      expect(change1).to receive(:select!)
      expect(change2).to receive(:unselect!)
      expect(change3).to receive(:select!)
    end
  end

  describe '#apply_selected_file_changes' do
    let(:diff1) { instance_double VCS::FileDiff }
    let(:diff2) { instance_double VCS::FileDiff }
    let(:unselected_file_changes) { %w[c1 c2] }

    before do
      allow(commit)
        .to receive(:unselected_file_changes).and_return unselected_file_changes
      allow(commit).to receive(:file_diffs).and_return [diff1, diff2]
      allow(diff1).to receive(:apply_selected_changes)
      allow(diff2).to receive(:apply_selected_changes)
      allow(commit).to receive(:generate_diffs)
    end

    after { commit.send :apply_selected_file_changes }

    it 'calls apply_selected_changes on each file_diff' do
      expect(diff1).to receive(:apply_selected_changes)
      expect(diff2).to receive(:apply_selected_changes)
    end

    it 're-generates file diffs' do
      expect(commit).to receive(:generate_diffs)
    end

    context 'when all file changes are selected' do
      let(:unselected_file_changes) { [] }

      it 'does not apply selected changes or regenerate diffs' do
        expect(diff1).not_to receive(:apply_selected_changes)
        expect(diff2).not_to receive(:apply_selected_changes)
        expect(commit).not_to receive(:generate_diffs)
      end
    end
  end

  describe '#update_files_in_branch' do
    subject(:update_files) { commit.send :update_files_in_branch }

    let(:branch) { commit.branch }

    before { allow(branch).to receive(:mark_files_as_committed) }

    it 'calls #mark_files_as_committed on branch' do
      update_files
      expect(branch).to have_received(:mark_files_as_committed).with(commit)
    end
  end
end

# frozen_string_literal: true

RSpec.describe Contribution, type: :model do
  subject(:contribution) { build :contribution }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  describe 'associations' do
    it { is_expected.to belong_to(:project).dependent(false) }
    it do
      is_expected
        .to belong_to(:creator).class_name('Profiles::User').dependent(false)
    end
    it do
      is_expected
        .to belong_to(:branch).class_name('VCS::Branch').dependent(:destroy)
    end
    it do
      is_expected
        .to belong_to(:origin_revision)
        .class_name('VCS::Commit')
        .dependent(false)
    end
  end

  describe 'delegations' do
    it do
      is_expected.to delegate_method(:branches).to(:project).with_prefix
      is_expected.to delegate_method(:master_branch).to(:project).with_prefix
      is_expected.to delegate_method(:revisions).to(:project).with_prefix
      is_expected.to delegate_method(:files).to(:branch)
    end
  end

  describe 'validations' do
    it do
      is_expected.to validate_presence_of(:project).with_message('must exist')
    end
    it do
      is_expected.to validate_presence_of(:creator).with_message('must exist')
    end
    it do
      is_expected.to validate_presence_of(:branch).with_message('must exist')
    end
    it do
      is_expected
        .to validate_presence_of(:origin_revision).with_message('must exist')
    end
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:description) }

    context 'on setup' do
      it { is_expected.to validate_absence_of(:branch).on(:setup) }
      it { is_expected.to validate_presence_of(:title).on(:setup) }
      it { is_expected.to validate_presence_of(:description).on(:setup) }
    end

    context 'when origin revision is not published' do
      let(:origin_revision) { contribution.origin_revision }

      before { allow(origin_revision).to receive(:published?).and_return false }

      it 'adds an error' do
        contribution.valid?
        expect(contribution.errors[:origin_revision])
          .to include('must be published')
      end
    end

    context 'when origin revision does not belong to project' do
      let(:origin_revision) { contribution.origin_revision }

      before { allow(origin_revision).to receive(:branch_id).and_return 'xx' }

      it 'adds an error' do
        contribution.valid?
        expect(contribution.errors[:origin_revision])
          .to include('must belong to the same project')
      end
    end
  end

  describe '#accept(revision:)' do
    subject(:accept) { contribution.accept(revision: revision) }

    let(:revision)                    { instance_double VCS::Commit }
    let(:master_branch)               { instance_double VCS::Branch }
    let(:file_diffs)                  { class_double VCS::FileDiff }
    let(:file_diffs_with_new_version) { class_double VCS::FileDiff }
    let(:creator)                     { contribution.creator }
    let!(:contribution) do
      create :contribution, project: project
    end
    let(:project) { create :project, :skip_archive_setup, :with_repository }
    let(:successfully_published) { true }

    before do
      allow(revision).to receive(:publish).and_return successfully_published
      allow(project).to receive(:master_branch).and_return master_branch
      allow(project).to receive(:master_branch_id).and_return 'master_branch_id'
      allow(contribution.origin_revision)
        .to receive(:branch_id).and_return 'master_branch_id'
      allow(VCS::Operations::RestoreFilesFromDiffs).to receive(:restore)
      allow(revision).to receive(:file_diffs).and_return file_diffs
      allow(file_diffs)
        .to receive(:includes)
        .with(:new_version)
        .and_return file_diffs_with_new_version
    end

    it { is_expected.to be true }

    it 'publishes the commit' do
      accept
      expect(revision)
        .to have_received(:publish)
        .with(author_id: creator.id,
              branch_id: 'master_branch_id',
              select_all_file_changes: true)
    end

    it 'applies changes to the master branch' do
      accept
      expect(VCS::Operations::RestoreFilesFromDiffs)
        .to have_received(:restore)
        .with(file_diffs: file_diffs_with_new_version,
              target_branch: master_branch)
    end

    it 'updates the contribution to accepted' do
      expect { accept }.to change(contribution, :accepted?).to(true)
    end

    context 'when contribution has already been accepted' do
      before { contribution.update_attribute(:is_accepted, true) }

      it { is_expected.to be false }

      it 'adds a validation error' do
        accept
        expect(contribution.errors.full_messages).to include(
          'Contribution has already been accepted.'
        )
      end

      it 'does not publish the commit' do
        accept
        expect(revision).not_to have_received(:publish)
      end

      it 'does not apply changes to the master branch' do
        accept
        expect(VCS::Operations::RestoreFilesFromDiffs)
          .not_to have_received(:restore)
      end
    end

    context 'when publication of revision fails' do
      let(:successfully_published) { false }

      it { is_expected.to be false }

      it 'does not apply changes to the master branch' do
        accept
        expect(VCS::Operations::RestoreFilesFromDiffs)
          .not_to have_received(:restore)
      end

      it 'does not persist contribution' do
        accept
        expect(contribution.changes).to be_any
      end
    end
  end

  describe '#accepted?' do
    let(:contribution) { create :contribution }

    it { is_expected.not_to be_accepted }

    context 'when is_accepted=true' do
      before { contribution.is_accepted = true }

      it { is_expected.not_to be_accepted }
    end

    context 'when is accepted and persisted' do
      before { contribution.update(is_accepted: true) }

      it { is_expected.to be_accepted }
    end
  end

  describe '#open?' do
    before { allow(contribution).to receive(:accepted?).and_return accepted }

    context 'when not accepted' do
      let(:accepted) { false }

      it { is_expected.to be_open }
    end

    context 'when accepted' do
      let(:accepted) { true }

      it { is_expected.not_to be_open }
    end
  end

  describe '#setup' do
    subject(:setup) { contribution.setup('attrs') }

    let(:is_valid) { true }

    before do
      allow(contribution).to receive(:assign_attributes)
      allow(contribution).to receive(:valid?).and_return is_valid
      allow(contribution).to receive(:fork_master_branch)
      allow(contribution).to receive(:grant_creator_write_access_to_branch)
      allow(contribution).to receive(:save).and_return 'result-of-save'

      setup
    end

    it do
      expect(contribution).to have_received(:assign_attributes).with('attrs')
    end
    it { expect(contribution).to have_received(:valid?).with(:setup) }
    it { expect(contribution).to have_received(:fork_master_branch) }
    it do
      expect(contribution)
        .to have_received(:grant_creator_write_access_to_branch)
    end
    it { expect(contribution).to have_received(:save) }

    it 'returns the result of #save' do
      is_expected.to eq 'result-of-save'
    end

    context 'when it is not valid for setup' do
      let(:is_valid) { false }

      it { is_expected.to eq false }
      it do
        expect(contribution).not_to have_received(:fork_master_branch)
        expect(contribution)
          .not_to have_received(:grant_creator_write_access_to_branch)
      end
    end

    context 'when called without attributes' do
      subject(:setup) { contribution.setup }

      it { expect(contribution).to have_received(:assign_attributes).with({}) }
    end
  end
end

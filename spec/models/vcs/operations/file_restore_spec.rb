# frozen_string_literal: true

RSpec.describe VCS::Operations::FileRestore, type: :model do
  subject(:file_restore) do
    described_class.new(snapshot: snapshot, target_branch: branch)
  end
  let(:snapshot)  { instance_double VCS::FileSnapshot }
  let(:branch)    { instance_double VCS::Branch }

  before { allow(snapshot).to receive(:file_id).and_return 'FRid' }

  describe '#restorable?' do
    let(:is_deletion)     { false }
    let(:is_addition)     { true }
    let(:is_modification) { true }
    let(:is_folder)       { false }
    let(:backup)          { nil }

    before do
      diff = instance_double VCS::FileDiff
      allow(file_restore).to receive(:diff).and_return diff
      allow(diff).to receive(:deletion?).and_return is_deletion
      allow(diff).to receive(:addition?).and_return is_addition
      allow(diff).to receive(:modification?).and_return is_modification
      allow(snapshot).to receive(:folder?).and_return is_folder
      allow(snapshot).to receive(:backup).and_return backup
    end

    it { is_expected.not_to be_restorable }

    context 'when diff is a deletion' do
      let(:is_deletion) { true }

      it { is_expected.to be_restorable }
    end

    context 'when snapshot is a folder' do
      let(:is_folder) { true }

      it { is_expected.to be_restorable }
    end

    context 'when backup is present' do
      let(:backup) { instance_double VCS::FileBackup }

      it { is_expected.to be_restorable }
    end

    context 'when diff is neither addition nor modification' do
      let(:is_addition)     { false }
      let(:is_modification) { false }

      it { is_expected.to be_restorable }
    end
  end
end

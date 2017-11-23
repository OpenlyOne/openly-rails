# frozen_string_literal: true

RSpec.describe FolderHelper, type: :helper do
  before { allow(NotificationChannelJob).to receive(:perform_later) }

  describe '#collect_parents(folder)' do
    subject(:method) { collect_parents(folder) }

    context 'when folder has three parents' do
      let(:project) { create :project }
      let(:f1)      { create :file_items_folder, project: project }
      let(:f2)      { create :file_items_folder, project: project, parent: f1 }
      let(:f3)      { create :file_items_folder, project: project, parent: f2 }
      let(:folder)  { create :file_items_folder, project: project, parent: f3 }

      it { is_expected.to eq [f1, f2, f3, folder] }
    end

    context 'when folder has two parents' do
      let(:project) { create :project }
      let(:f1)      { create :file_items_folder, project: project }
      let(:f2)      { create :file_items_folder, project: project, parent: f1 }
      let(:folder)  { create :file_items_folder, project: project, parent: f2 }

      it { is_expected.to eq [f1, f2, folder] }
    end

    context 'when folder has no parent' do
      let(:project) { create :project }
      let(:folder)  { create :file_items_folder, project: project }

      it { is_expected.to eq [folder] }
    end
  end
end

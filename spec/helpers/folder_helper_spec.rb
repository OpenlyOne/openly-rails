# frozen_string_literal: true

RSpec.describe FolderHelper, type: :helper do
  describe '#change_color(file)' do
    subject(:method) { change_color(file) }
    let(:file) { build_stubbed :file_items_base, :committed }

    context 'when file has been deleted' do
      before { allow(file).to receive(:deleted_since_last_commit?) { true } }
      it { is_expected.to eq 'red darken-2' }
    end

    context 'when file has been added' do
      before { allow(file).to receive(:added_since_last_commit?) { true } }
      it { is_expected.to eq 'green darken-2' }
    end

    context 'when file has been modified' do
      before { allow(file).to receive(:modified_since_last_commit?) { true } }
      it { is_expected.to eq 'amber darken-4' }
    end

    context 'when file has been moved' do
      before { allow(file).to receive(:moved_since_last_commit?) { true } }
      it { is_expected.to eq 'purple darken-2' }
    end

    context 'when file has not been changed' do
      it { is_expected.to eq '' }
    end
  end

  describe '#change_text_color(file)' do
    subject(:method) { change_text_color(file) }
    let(:file) { build_stubbed :file_items_base, :committed }

    context 'when file has been deleted' do
      before { allow(file).to receive(:deleted_since_last_commit?) { true } }
      it { is_expected.to eq 'red-text text-darken-2' }
    end

    context 'when file has been added' do
      before { allow(file).to receive(:added_since_last_commit?) { true } }
      it { is_expected.to eq 'green-text text-darken-2' }
    end

    context 'when file has been modified' do
      before { allow(file).to receive(:modified_since_last_commit?) { true } }
      it { is_expected.to eq 'amber-text text-darken-4' }
    end

    context 'when file has been moved' do
      before do
        allow(file).to receive(:moved_since_last_commit?).and_return true
      end
      it { is_expected.to eq 'purple-text text-darken-2' }
    end

    context 'when file has not been changed' do
      it { is_expected.to eq '' }
    end
  end

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

  describe '#file_change_html_class(file)' do
    subject(:method) { file_change_html_class(file) }
    let(:file) { build_stubbed :file_items_base, :committed }

    context 'when file has been deleted' do
      before { allow(file).to receive(:deleted_since_last_commit?) { true } }
      it { is_expected.to eq 'changed deleted' }
    end

    context 'when file has been added' do
      before { allow(file).to receive(:added_since_last_commit?) { true } }
      it { is_expected.to eq 'changed added' }
    end

    context 'when file has been modified' do
      before { allow(file).to receive(:modified_since_last_commit?) { true } }
      it { is_expected.to eq 'changed modified' }
    end

    context 'when file has been moved' do
      before { allow(file).to receive(:moved_since_last_commit?) { true } }
      it { is_expected.to eq 'changed moved' }
    end

    context 'when file has not been changed' do
      it { is_expected.to eq 'unchanged' }
    end
  end

  describe '#file_change_icon(file)' do
    subject(:method) { file_change_icon(file) }
    let(:file) { build_stubbed :file_items_base, :committed }

    context 'when file has been deleted' do
      before { allow(file).to receive(:deleted_since_last_commit?) { true } }
      it { is_expected.to be_a String }
    end

    context 'when file has been added' do
      before { allow(file).to receive(:added_since_last_commit?) { true } }
      it { is_expected.to be_a String }
    end

    context 'when file has been modified' do
      before { allow(file).to receive(:modified_since_last_commit?) { true } }
      it { is_expected.to be_a String }
    end

    context 'when file has been moved' do
      before { allow(file).to receive(:moved_since_last_commit?) { true } }
      it { is_expected.to be_a String }
    end

    context 'when file has not been changed' do
      it { is_expected.to eq nil }
    end
  end

  describe '#file_change_tooltip(file)' do
    subject(:method) { file_change_tooltip(file) }
    let(:file) { build_stubbed :file_items_base, :committed }

    context 'when file has been deleted' do
      before { allow(file).to receive(:deleted_since_last_commit?) { true } }
      it { is_expected.to eq 'File has been deleted' }
    end

    context 'when file has been added' do
      before { allow(file).to receive(:added_since_last_commit?) { true } }
      it { is_expected.to eq 'File has been added' }
    end

    context 'when file has been modified' do
      before { allow(file).to receive(:modified_since_last_commit?) { true } }
      it { is_expected.to eq 'File has been modified' }
    end

    context 'when file has been moved' do
      before { allow(file).to receive(:moved_since_last_commit?) { true } }
      it { is_expected.to eq 'File has been moved' }
    end

    context 'when file has not been changed' do
      it { is_expected.to eq nil }
    end
  end
end

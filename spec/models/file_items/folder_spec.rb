# frozen_string_literal: true

require 'models/shared_examples/being_a_file_item.rb'

RSpec.describe FileItems::Folder, type: :model do
  subject(:folder) { build(:file_items_folder) }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  it_should_behave_like 'being a file item'

  describe 'associations' do
    it do
      is_expected.to(
        have_many(:children)
          .class_name('FileItems::Base')
          .dependent(:destroy)
          .with_foreign_key(:parent_id)
          .inverse_of(:parent)
      )
    end
  end

  describe 'callbacks' do
    context 'before_destroy' do
      context 'when folder has been added since the last commit' do
        let(:subject) { create :file_items_folder }

        it 'calls #reset_parent_id_of_committed_children' do
          expect(subject).to receive(:reset_parent_id_of_committed_children)
          subject.destroy
        end

        it 'resets parent IDs before destroying children' do
          old_folder = create :file_items_folder, project: subject.project
          create_list :file_items_base, 3, :committed,
                      project: subject.project,
                      parent: subject, parent_id_at_last_commit: old_folder.id
          subject.destroy
          expect(old_folder.children.count).to eq 3
        end
      end

      context 'when folder has been committed' do
        let(:subject) { create :file_items_folder, :committed }

        it 'does not call #reset_parent_id_of_committed_children' do
          expect(subject)
            .not_to receive(:reset_parent_id_of_committed_children)
          subject.destroy
        end
      end
    end
  end

  describe '#create_child_from_change(change)' do
    subject(:method)  { folder.create_child_from_change(change_item) }
    let(:folder)      { create :file_items_folder }
    let(:change_item) { build :google_drive_change }
    let(:project)     { folder.project }
    let(:new_file) do
      FileItems::Base.find_by(
        project: project,
        google_drive_id: change_item.file_id
      )
    end

    it 'adds the file' do
      expect { subject }.to(
        change { FileItems::Base.where(project: project).count }.by(1)
      )
    end

    it 'saves the file project ID' do
      subject
      expect(new_file.project_id).to eq folder.project_id
    end

    it 'saves the file parent ID' do
      subject
      expect(new_file.parent_id).to eq folder.id
    end

    it 'saves the file ID' do
      subject
      expect(new_file.google_drive_id).to eq change_item.file_id
    end

    it 'saves the file mime type' do
      subject
      expect(new_file.mime_type).to eq change_item.file.mime_type
    end

    it 'saves the file version' do
      subject
      expect(new_file.version).to eq change_item.file.version
    end

    it 'saves the file name' do
      subject
      expect(new_file.name).to eq change_item.file.name
    end

    it 'saves the file modified time' do
      subject
      expect(new_file.modified_time.to_i)
        .to eq change_item.file.modified_time.to_i
    end

    it 'marks file as added' do
      subject
      expect(new_file).to be_added_since_last_commit
    end
  end

  describe '#external_link' do
    subject(:method) { folder.external_link }

    context "when google drive id is 'abc'" do
      before { folder.google_drive_id = 'abc' }
      it { is_expected.to eq 'https://drive.google.com/drive/folders/abc' }
    end

    context "when google drive id is '1234'" do
      before { folder.google_drive_id = '1234' }
      it { is_expected.to eq 'https://drive.google.com/drive/folders/1234' }
    end
    context 'when google drive id is nil' do
      before { folder.google_drive_id = nil }
      it { is_expected.to eq nil }
    end
  end

  describe '#icon' do
    it { expect(subject.icon).to eq('files/folder.png') }
  end

  describe '#reset_parent_id_of_committed_children' do
    subject(:method)    { folder.send :reset_parent_id_of_committed_children }
    let!(:folder)       { create :file_items_folder }
    let!(:old_folder)   { create :file_items_folder, project: folder.project }
    let!(:new_children) { create_list :file_items_base, 3, parent: folder }
    let!(:committed_children) do
      create_list :file_items_base, 3,
                  :committed,
                  parent: folder,
                  parent_id_at_last_commit: old_folder.id
    end

    it 'resets parent ID of committed child files' do
      subject
      committed_children.each do |file|
        expect(file.reload.parent_id).to eq old_folder.id
      end
    end

    it 'does not reset parent ID of newly added child files' do
      subject
      new_children.each do |file|
        expect(file.reload.parent_id).to eq folder.id
      end
    end
  end
end

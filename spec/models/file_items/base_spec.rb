# frozen_string_literal: true

require 'models/shared_examples/being_a_file_item.rb'

RSpec.describe FileItems::Base, type: :model do
  subject(:base) { build(:file_items_base) }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  it_should_behave_like 'being a file item'

  context 'Single Table Inheritance Mime Types' do
    subject(:first_item)  { FileItems::Base.first }
    before                { create :file_items_base, mime_type: folder_type }

    context 'when mime type is folder' do
      let(:folder_type) { 'application/vnd.google-apps.folder' }
      it { is_expected.to be_a FileItems::Folder }
    end

    context 'when mime type is document' do
      let(:folder_type) { 'application/vnd.google-apps.document' }
      it { is_expected.to be_a FileItems::Document }
    end

    context 'when mime type is spreadsheet' do
      let(:folder_type) { 'application/vnd.google-apps.spreadsheet' }
      it { is_expected.to be_a FileItems::Spreadsheet }
    end

    context 'when mime type is presentation' do
      let(:folder_type) { 'application/vnd.google-apps.presentation' }
      it { is_expected.to be_a FileItems::Presentation }
    end

    context 'when mime type is drawing' do
      let(:folder_type) { 'application/vnd.google-apps.drawing' }
      it { is_expected.to be_a FileItems::Drawing }
    end

    context 'when mime type is form' do
      let(:folder_type) { 'application/vnd.google-apps.form' }
      it { is_expected.to be_a FileItems::Form }
    end

    context 'when mime type is anything else' do
      let(:folder_type) { 'some-imaginary-mime-type' }
      it { is_expected.to be_a FileItems::Base }
    end

    context 'when mime type is empty' do
      let(:folder_type) { '' }
      it { is_expected.to be_a FileItems::Base }
    end
  end

  describe '.update_all_projects_from_change(change)' do
    subject(:method) do
      FileItems::Base.update_all_projects_from_change(change_item)
    end
    let(:project)     { create :project }
    let!(:new_parent) { create :file_items_folder, project: project }
    let!(:file)       { create :file_items_base, project: project }
    let(:change_item) do
      build :google_drive_change,
            id: file.google_drive_id,
            parent: new_parent.google_drive_id
    end

    it 'calls update_single_project_from_change' do
      expect(FileItems::Base).to receive(:update_single_project_from_change)
        .with(project, change_item)
      subject
    end

    context 'when change is not of type: file' do
      before { change_item.type = 'comment' }

      it 'does not update any files' do
        expect(FileItems::Base)
          .not_to receive(:update_single_project_from_change)
        subject
      end
    end

    context 'when change does not have the file attribute' do
      before { change_item.file = nil }

      it 'calls update_single_project_from_change' do
        expect(FileItems::Base).to receive(:update_single_project_from_change)
          .with(project, change_item)
        subject
      end
    end

    context 'when change file parents are nil' do
      before { change_item.file.parents = nil }

      it 'calls update_single_project_from_change' do
        expect(FileItems::Base).to receive(:update_single_project_from_change)
          .with(project, change_item)
        subject
      end
    end

    context 'when two files are affected by the change' do
      let(:project2) { create :project }
      let!(:new_parent2) do
        create :file_items_folder,
               google_drive_id: new_parent.google_drive_id,
               project: project2
      end
      let!(:file2) do
        create :file_items_base,
               google_drive_id: file.google_drive_id,
               project: project2
      end
      before do
        allow(FileItems::Base).to receive(:update_single_project_from_change)
      end

      it 'calls update_single_project_from_change for project 1' do
        expect(FileItems::Base).to receive(:update_single_project_from_change)
          .with(project, change_item)
        subject
      end

      it 'calls update_single_project_from_change for project 2' do
        expect(FileItems::Base).to receive(:update_single_project_from_change)
          .with(project2, change_item)
        subject
      end
    end
  end

  describe '#external_link' do
    subject(:method) { base.external_link }

    context "when google drive id is 'abc'" do
      before { base.google_drive_id = 'abc' }
      it { is_expected.to eq 'https://drive.google.com/file/d/abc' }
    end

    context "when google drive id is '1234'" do
      before { base.google_drive_id = '1234' }
      it { is_expected.to eq 'https://drive.google.com/file/d/1234' }
    end
    context 'when google drive id is nil' do
      before { base.google_drive_id = nil }
      it { is_expected.to eq nil }
    end
  end

  describe '#icon' do
    context 'when mime type is abc' do
      before { subject.mime_type = 'abc' }
      it {
        expect(subject.icon).to eq(
          'https://drive-thirdparty.googleusercontent.com/128/type/' \
          'abc'
        )
      }
    end

    context 'when mime type is application/vnd.google-apps.12345' do
      before { subject.mime_type = 'application/vnd.google-apps.12345' }
      it {
        expect(subject.icon).to eq(
          'https://drive-thirdparty.googleusercontent.com/128/type/' \
          'application/vnd.google-apps.12345'
        )
      }
    end

    context 'when mime_type is nil' do
      before { subject.mime_type = nil }
      it { expect(subject.icon).to eq nil }
    end
  end

  describe '.update_single_project_from_change(file, parent, change)' do
    subject(:method) do
      FileItems::Base.send(
        :update_single_project_from_change, project, change_item
      )
    end
    let(:project)             { create :project }
    let(:current_parent)      { create :file_items_folder, project: project }
    let(:new_parent)          { current_parent }
    let(:file) do
      create :file_items_base,
             project: project,
             parent: current_parent
    end
    let(:new_parent_drive_id) { new_parent.google_drive_id }
    let(:file_drive_id)       { file.google_drive_id }
    let!(:change_item) do
      build :google_drive_change,
            id: file_drive_id,
            parent: new_parent_drive_id
    end

    context 'when file and parent exist' do
      it 'updates the file from change' do
        expect_any_instance_of(FileItems::Base).to receive(:update_from_change)
          .with(new_parent, change_item) do |instance, *_args|
            expect(instance.attributes).to eq file.reload.attributes
          end
        subject
      end
    end

    context 'when file exists but not parent' do
      let(:new_parent_drive_id) { 'abc' }
      let(:new_parent)          { nil }

      it 'updates the file from change' do
        expect_any_instance_of(FileItems::Base).to receive(:update_from_change)
          .with(new_parent, change_item) do |instance, *_args|
            expect(instance.attributes).to eq file.reload.attributes
          end
        subject
      end
    end

    context 'when parent exists but not file' do
      let(:file_drive_id) { 'abc' }
      let(:file)          { nil }

      it 'creates a child from change' do
        expect_any_instance_of(FileItems::Folder)
          .to receive(:create_child_from_change)
          .with(change_item) do |instance, *_args|
            expect(instance.attributes).to eq new_parent.reload.attributes
          end
        subject
      end
    end

    context 'when change file parents are nil' do
      before { change_item.file.parents = nil }

      it 'updates the file from change' do
        expect_any_instance_of(FileItems::Base).to receive(:update_from_change)
          .with(nil, change_item) do |instance, *_args|
            expect(instance.attributes).to eq file.reload.attributes
          end
        subject
      end
    end

    context 'when change does not have the file attribute' do
      before { change_item.file = nil }

      it 'updates the file from change' do
        expect_any_instance_of(FileItems::Base).to receive(:update_from_change)
          .with(nil, change_item) do |instance, *_args|
            expect(instance.attributes).to eq file.reload.attributes
          end
        subject
      end
    end
  end
end

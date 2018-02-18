# frozen_string_literal: true

RSpec.describe StagedFile, type: :model do
  subject(:staged_file) { build :staged_file }

  describe 'associations' do
    it { is_expected.to belong_to(:project).dependent(false) }
    it { is_expected.to belong_to(:file_resource).dependent(false) }
  end

  describe 'attributes' do
    it { is_expected.to have_readonly_attribute(:is_root) }
  end

  describe 'validations' do
    context 'when staged file with project and file_resource already exists' do
      let(:project)       { staged_file.project }
      let(:file_resource) { staged_file.file_resource }

      before do
        create :staged_file, project: project, file_resource: file_resource
      end

      it { is_expected.to be_invalid }
    end

    context 'when staged file with is_root=true already exists for project' do
      subject(:staged_file) { build :staged_file, :root }
      let(:project)         { staged_file.project }

      before { create :staged_file, :root, project: project }

      it { is_expected.to be_invalid }
    end
  end

  describe 'read-only instance' do
    context 'on create' do
      it { expect { staged_file.save }.not_to raise_error }
    end

    context 'on update' do
      let(:staged_file) { create :staged_file }
      it do
        expect { staged_file.save }.to raise_error ActiveRecord::ReadOnlyRecord
      end
    end

    context 'on destroy' do
      let(:staged_file) { create :staged_file }
      it { expect { staged_file.destroy }.not_to raise_error }

      context 'when staged file is root' do
        let(:staged_file) { create :staged_file, :root }
        it do
          expect { staged_file.destroy }
            .to raise_error ActiveRecord::ReadOnlyRecord
        end
      end
    end
  end
end

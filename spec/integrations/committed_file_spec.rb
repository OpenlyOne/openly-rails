# frozen_string_literal: true

RSpec.describe CommittedFile, type: :model do
  subject(:file) { build(:committed_file) }

  describe 'validation: file resource snapshot must belong to file resource' do
    let(:file_resource) { file.file_resource }
    before              { file.file_resource_snapshot = snapshot }

    context 'when file resource snapshot belongs to file resource' do
      let(:snapshot) { file_resource.current_snapshot }
      it             { is_expected.to be_valid }
    end

    context 'when file resource snapshot does not belong to file resource' do
      let(:snapshot) { create(:file_resource_snapshot) }
      it             { is_expected.to be_invalid }
    end
  end
end

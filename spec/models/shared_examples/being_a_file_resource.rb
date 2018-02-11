# frozen_string_literal: true

RSpec.shared_examples 'being a file resource' do
  subject { file_resource }

  describe 'attributes' do
    it { is_expected.to have_readonly_attribute(:provider_id) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:provider_id) }
    it { is_expected.to validate_presence_of(:external_id) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:mime_type) }
    it { is_expected.to validate_presence_of(:content_version) }
    it do
      is_expected
        .to validate_uniqueness_of(:external_id).scoped_to(:provider_id)
    end

    context 'when external id has not changed' do
      before do
        allow(file_resource).to receive(:external_id_changed?).and_return false
      end

      it { expect(file_resource).not_to validate_uniqueness_of(:external_id) }
    end

    context 'when file is deleted' do
      before { allow(file_resource).to receive(:deleted?).and_return true }

      it { is_expected.not_to validate_presence_of(:name) }
      it { is_expected.not_to validate_presence_of(:mime_type) }
      it { is_expected.not_to validate_presence_of(:content_version) }
    end
  end

  describe 'type casting' do
    subject(:file_from_db) { FileResource.find(file.id) }
    before { file.save! }
    it { expect(file_from_db).to be_an_instance_of described_class }
  end

  describe '#deleted?' do
    subject(:deleted) { file_resource.deleted? }

    it { is_expected.to be false }

    context 'when is_deleted = true' do
      before { allow(file_resource).to receive(:is_deleted).and_return true }

      it { is_expected.to be true }
    end
  end
end

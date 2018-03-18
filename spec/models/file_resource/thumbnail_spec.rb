# frozen_string_literal: true

RSpec.describe FileResource::Thumbnail, type: :model do
  subject(:thumbnail) { build :file_resource_thumbnail }

  it { should have_attached_file(:image) }

  describe 'validations' do
    it { is_expected.to validate_attachment_presence(:image) }
    it do
      is_expected
        .to validate_attachment_content_type(:image)
        .allowing('image/png', 'image/gif', 'image/jpeg')
        .rejecting('text/plain', 'text/xml')
    end
    it do
      is_expected
        .to validate_attachment_size(:image)
        .less_than(1.megabyte)
    end
    it do
      is_expected
        .to validate_uniqueness_of(:version_id)
        .scoped_to(%i[external_id provider_id])
        .with_message('with external ID and provider already exist')
    end
  end

  describe 'read-only instance' do
    context 'on create' do
      it { expect { thumbnail.save }.not_to raise_error }
    end

    context 'on update' do
      let(:thumbnail) { create :file_resource_thumbnail }
      it do
        expect { thumbnail.save }.to raise_error ActiveRecord::ReadOnlyRecord
      end
    end

    context 'on destroy' do
      let(:thumbnail) { create :file_resource_thumbnail }
      it { expect { thumbnail.destroy }.not_to raise_error }
    end
  end
end

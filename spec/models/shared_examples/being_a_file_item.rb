# frozen_string_literal: true

RSpec.shared_examples 'being a file item' do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it {
      is_expected.to belong_to(:parent).class_name('FileItems::Folder')
      # .optional <- TODO: Upgrade shoulda-matchers gem and enable optional
    }
  end

  describe '#external_link' do
    it { expect(subject).to respond_to :external_link }
  end
end

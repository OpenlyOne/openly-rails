# frozen_string_literal: true

RSpec.shared_examples 'being a profile' do
  describe 'route keys' do
    it 'should have singular route key: profile' do
      expect(subject.model_name.singular_route_key).to eq 'profile'
    end
    it 'should have route key: profiles' do
      expect(subject.model_name.route_key).to eq 'profiles'
    end
  end

  describe 'associations' do
    it do
      is_expected
        .to have_many(:projects)
        .with_foreign_key(:owner_id)
        .dependent(:destroy)
        .inverse_of(:owner)
    end
    it do
      is_expected
        .to have_and_belong_to_many(:collaborations)
        .class_name('Project').validate(false)
    end
  end

  describe 'attachments' do
    it { is_expected.to have_attached_file(:picture) }
    it { is_expected.to have_attached_file(:banner) }
  end

  describe 'attributes' do
    it { is_expected.to have_readonly_attribute(:handle) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of :handle }
    it { is_expected.to validate_uniqueness_of(:handle).case_insensitive }
    it do
      is_expected
        .to validate_length_of(:handle).is_at_least(3).is_at_most(26)
    end
    context 'when validating handle' do
      it 'special characters are invalid' do
        subject.handle = 'a*<>$@/r?!'
        is_expected.to be_invalid
      end

      it 'an underscore at the beginning is invalid' do
        subject.handle = '_' + subject.handle
        is_expected.to be_invalid
      end

      it 'an underscore at the end is invalid' do
        subject.handle += '_'
        is_expected.to be_invalid
      end
    end

    it do
      is_expected
        .to validate_attachment_content_type(:picture)
        .allowing('image/png', 'image/gif', 'image/jpeg')
        .rejecting('text/plain', 'text/xml', 'application/pdf')
    end

    it do
      is_expected.to validate_attachment_size(:picture).less_than(10.megabytes)
    end

    it 'validates that color scheme is a valid option' do
      # TODO: Remove shoulda-matchers test string hardcoding below
      is_expected.to validate_inclusion_of(:color_scheme)
        .in_array(Color.options)
        .with_message('shoulda-matchers test string is not a valid option')
    end
  end

  describe '#color_scheme_with_font_color' do
    subject(:method)  { profile.color_scheme_with_font_color }
    before            { profile.color_scheme = color_scheme }

    context "when color scheme is 'indigo base'" do
      let(:color_scheme) { 'indigo base' }
      it { is_expected.to eq 'indigo base white-text' }
    end

    context "when color scheme is 'red lighten-4'" do
      let(:color_scheme) { 'red lighten-4' }
      it { is_expected.to eq 'red lighten-4 black-text' }
    end

    context "when color scheme is 'amber accent-2'" do
      let(:color_scheme) { 'amber accent-2' }
      it { is_expected.to eq 'amber accent-2 black-text' }
    end
  end

  describe '#to_param' do
    it 'returns the handle' do
      expect(subject.to_param).to eq subject.handle
    end

    context 'when handle is nil' do
      before { subject.handle = nil }

      it 'returns nil' do
        expect(subject.to_param).to eq nil
      end
    end
  end
end

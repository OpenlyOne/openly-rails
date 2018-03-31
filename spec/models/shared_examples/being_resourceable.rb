# frozen_string_literal: true

RSpec.shared_examples 'being resourceable' do
  describe 'associations' do
    it do
      is_expected
        .to belong_to(:thumbnail)
        .class_name('FileResource::Thumbnail')
        .dependent(false)
        .optional
    end
  end

  describe '#folder?' do
    before do
      allow(resourceable)
        .to receive(:provider_mime_type_class).and_return mime_type_class
      allow(resourceable).to receive(:mime_type).and_return 'type'
      allow(mime_type_class)
        .to receive(:folder?).with('type').and_return is_folder
    end

    context 'when it is folder' do
      let(:is_folder) { true }
      it              { is_expected.to be_folder }
    end

    context 'when it is not folder' do
      let(:is_folder) { false }
      it              { is_expected.not_to be_folder }
    end
  end

  describe '#external_link' do
    subject { resourceable.external_link }

    before do
      allow(resourceable)
        .to receive(:provider_link_class).and_return link_class
      allow(resourceable).to receive(:mime_type).and_return 'type'
      allow(resourceable).to receive(:external_id).and_return 'external-id'
      allow(link_class)
        .to receive(:for)
        .with(external_id: 'external-id', mime_type: 'type')
        .and_return 'external-link-to-file'
    end

    it { is_expected.to eq 'external-link-to-file' }
  end

  describe '#icon' do
    subject { resourceable.icon }

    before do
      allow(resourceable)
        .to receive(:provider_icon_class).and_return icon_class
      allow(resourceable).to receive(:mime_type).and_return 'type'
      allow(icon_class)
        .to receive(:for).with(mime_type: 'type').and_return 'icon.png'
    end

    it { is_expected.to eq 'icon.png' }
  end

  describe '#provider' do
    subject { resourceable.provider }

    before do
      allow(resourceable).to receive(:provider_id).and_return 'id'
      allow(Provider).to receive(:find).with('id').and_return 'provider'
    end

    it { is_expected.to eq 'provider' }
  end

  describe '#symbolic_mime_type' do
    subject { resourceable.symbolic_mime_type }

    before do
      allow(resourceable)
        .to receive(:provider_mime_type_class).and_return mime_type_class
      allow(resourceable).to receive(:mime_type).and_return 'type'
      allow(mime_type_class)
        .to receive(:to_symbol).with('type').and_return :symbol
    end

    it { is_expected.to eq :symbol }
  end

  describe '#thumbnail_image' do
    subject(:thumbnail_image) { resourceable.thumbnail_image }
    let(:thumbnail)           { nil }

    before { allow(resourceable).to receive(:thumbnail).and_return thumbnail }

    it { is_expected.to be nil }

    context 'when thumbnail is present' do
      let(:thumbnail) { instance_double FileResource::Thumbnail }
      before { allow(thumbnail).to receive(:image).and_return 'image' }
      it { is_expected.to eq 'image' }
    end
  end

  describe '#thumbnail_image_or_fallback' do
    subject(:thumbnail_image) { resourceable.thumbnail_image_or_fallback }
    let(:image)               { 'image' }
    let(:thumbnail)           { instance_double FileResource::Thumbnail }

    before do
      allow(resourceable).to receive(:thumbnail_image).and_return image
      allow(FileResource::Thumbnail).to receive(:new).and_return thumbnail
      allow(thumbnail).to receive(:image).and_return 'fallback-image'
    end

    it { is_expected.to eq 'image' }

    context 'when image thumbnail_image is nil' do
      let(:image) { nil }

      it { is_expected.to eq 'fallback-image' }
    end
  end

  describe '#provider_icon_class' do
    subject { resourceable.send(:provider_icon_class) }
    it      { is_expected.to eq icon_class }
  end

  describe '#provider_link_class' do
    subject { resourceable.send(:provider_link_class) }
    it      { is_expected.to eq link_class }
  end

  describe '#provider_mime_type_class' do
    subject { resourceable.send(:provider_mime_type_class) }
    it      { is_expected.to eq mime_type_class }
  end
end

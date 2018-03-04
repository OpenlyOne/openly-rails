# frozen_string_literal: true

RSpec.shared_examples 'being resourceable' do
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

  describe '#provider_link_class' do
    subject { resourceable.send(:provider_link_class) }
    it      { is_expected.to eq link_class }
  end

  describe '#provider_mime_type_class' do
    subject { resourceable.send(:provider_mime_type_class) }
    it      { is_expected.to eq mime_type_class }
  end
end

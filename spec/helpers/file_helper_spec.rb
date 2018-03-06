# frozen_string_literal: true

RSpec.describe FileHelper, type: :helper do
  describe '#link_to_file(file, project, options = {})' do
    subject(:method)  { helper.link_to_file(file, project) {} }
    let(:project)     { build_stubbed :project }
    let(:file)        { instance_double FileResource::Snapshot }
    let(:is_folder)   { false }

    before { allow(file).to receive(:folder?).and_return is_folder }
    before { allow(file).to receive(:external_id).and_return 'external-id' }
    before { allow(file).to receive(:external_link).and_return 'external-link' }

    context 'when file is folder' do
      let(:is_folder) { true }

      it 'returns internal link to directory' do
        expect(helper).to receive(:link_to).with(
          "/#{project.owner.handle}/#{project.slug}/folders/external-id",
          any_args
        )
        method
      end

      it 'does not set target to _blank' do
        expect(helper).to receive(:link_to).with(kind_of(String), {})
        method
      end
    end

    context 'when file is not directory' do
      let(:is_folder) { false }

      it 'sets url to external_link_for_file' do
        expect(helper).to receive(:link_to).with('external-link', kind_of(Hash))
        method
      end

      it 'sets target to _blank' do
        expect(helper).to receive(:link_to).with(
          kind_of(String),
          hash_including(target: '_blank')
        )
        method
      end
    end

    context 'when options are passed' do
      subject(:method)  { helper.link_to_file(file, project, options) {} }
      let(:options)     { {} }

      it 'does not modify the passed options hash' do
        expect { method }.not_to(change { options })
      end

      context "when options include target: '_blank'" do
        let(:options) { { target: '_blank' } }

        it 'passes options to #link_to' do
          expect(helper)
            .to receive(:link_to)
            .with(kind_of(String), hash_including(target: '_blank'))
          method
        end
      end
    end
  end

  describe '#sort_files!(files)' do
    subject(:method)  { helper.sort_files!(files) }
    let(:files)       { %w[f1 f2 f3] }

    before do
      allow(helper).to receive(:sort_order_for_files).with('f1').and_return 3
      allow(helper).to receive(:sort_order_for_files).with('f2').and_return 2
      allow(helper).to receive(:sort_order_for_files).with('f3').and_return 1
    end

    it { is_expected.to eq %w[f3 f2 f1] }
  end

  describe '#sort_order_for_files' do
    subject(:method)  { helper.sort_order_for_files(file) }
    let(:file)        { build_stubbed :file_resource, name: 'File Name' }

    it { is_expected.to be_an Array }

    it 'parses file names as case insensitive' do
      expect(method.last).to eq 'file name'
    end

    context 'when file is directory' do
      before { allow(file).to receive(:folder?).and_return true }
      it { is_expected.to eq [0, 'file name'] }
    end

    context 'when file is not directory' do
      before { allow(file).to receive(:folder?).and_return false }
      it { is_expected.to eq [1, 'file name'] }
    end
  end
end

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
end

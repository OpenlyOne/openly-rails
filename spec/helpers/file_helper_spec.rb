# frozen_string_literal: true

RSpec.describe FileHelper, type: :helper do
  describe '#external_link_for_file(file)' do
    subject(:method)  { helper.external_link_for_file(file) }
    let(:mime_type)   { 'abc' }
    let(:file)        { build :file, id: 'FILE-ID', mime_type: mime_type }

    context 'when mime type is folder' do
      before { allow(helper).to receive(:type_of_file).and_return :folder }
      it { is_expected.to eq 'https://drive.google.com/drive/folders/FILE-ID' }
    end

    context 'when mime type is document' do
      before { allow(helper).to receive(:type_of_file).and_return :document }
      it { is_expected.to eq 'https://docs.google.com/document/d/FILE-ID' }
    end

    context 'when mime type is spreadsheet' do
      before { allow(helper).to receive(:type_of_file).and_return :spreadsheet }
      it { is_expected.to eq 'https://docs.google.com/spreadsheets/d/FILE-ID' }
    end

    context 'when mime type is presentation' do
      before do
        allow(helper).to receive(:type_of_file).and_return :presentation
      end
      it { is_expected.to eq 'https://docs.google.com/presentation/d/FILE-ID' }
    end

    context 'when mime type is drawing' do
      before { allow(helper).to receive(:type_of_file).and_return :drawing }
      it { is_expected.to eq 'https://docs.google.com/drawings/d/FILE-ID' }
    end

    context 'when mime type is form' do
      before { allow(helper).to receive(:type_of_file).and_return :form }
      it { is_expected.to eq 'https://docs.google.com/forms/d/FILE-ID' }
    end

    context 'when mime type is anything else' do
      before { allow(helper).to receive(:type_of_file).and_return :other }
      it { is_expected.to eq 'https://drive.google.com/file/d/FILE-ID' }
    end

    context 'when mime type is empty' do
      let(:mime_type) { '' }
      it              { is_expected.to eq nil }
    end
  end

  describe '#icon_for_file(file)' do
    subject(:method)  { helper.icon_for_file(file) }
    let(:mime_type)   { 'abc' }
    let(:file)        { build :file, mime_type: mime_type }

    context 'when mime type is folder' do
      before  { allow(helper).to receive(:type_of_file).and_return :folder }
      it      { is_expected.to eq 'files/folder.png' }
    end

    context 'when mime type is: mtype' do
      let(:mime_type) { 'mtype' }
      it do
        is_expected
          .to eq 'https://drive-thirdparty.googleusercontent.com/128/type/mtype'
      end
    end

    context 'when mime type is empty' do
      let(:mime_type) { '' }
      it              { is_expected.to eq nil }
    end
  end

  describe '#link_to_file(file, project, options = {})' do
    subject(:method)  { helper.link_to_file(file, project) {} }
    let(:project)     { create :project }

    context 'when file is directory' do
      let(:file) { build :file, :folder }

      it 'returns internal link to directory' do
        expect(helper).to receive(:link_to).with(
          "/#{project.owner.handle}/#{project.slug}/folders/#{file.id}",
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
      let(:file) { build :file }

      it 'sets url to external_link_for_file' do
        expect(helper).to receive(:link_to).with(
          external_link_for_file(file),
          kind_of(Hash)
        )
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

    context "when options include target: '_blank'" do
      subject(:method)  { helper.link_to_file(file, project, options) {} }
      let(:file)        { build :file, :folder }
      let(:options)     { { target: '_blank' } }

      it 'passes options to #link_to' do
        expect(helper)
          .to receive(:link_to)
          .with(kind_of(String), hash_including(target: '_blank'))
        method
      end
    end
  end

  describe '#sort_files(files)' do
    subject(:method)  { sort_files!(files) }
    let(:files)       { [dir1, dir2, dir3, file1, file2, file3].shuffle }
    let(:dir1)        { build :file, :folder, name: 'A Folder' }
    let(:dir2)        { build :file, :folder, name: 'Homework' }
    let(:dir3)        { build :file, :folder, name: 'Something Great' }
    let(:file1)       { build :file, name: 'A Funny File' }
    let(:file2)       { build :file, name: 'Financials' }
    let(:file3)       { build :file, name: 'Potato Soup Recipe' }

    it { is_expected.to eq [dir1, dir2, dir3, file1, file2, file3] }

    it 'modifies the files parameter' do
      expect { subject }.to(change { files })
    end

    it 'puts directories first' do
      subject
      expect(files[0..2].map(&:directory?)).to eq [true, true, true]
      expect(files[3..5].map(&:directory?)).to eq [false, false, false]
    end

    it 'puts files in alphabetical order' do
      subject
      last_file = files[0]
      files[1..2].each do |file|
        # expect file name to come later (alphabetically) than last_file's name
        expect(file.name > last_file.name).to be true

        # set last_file to current file for next comparison
        last_file = file
      end

      last_file = files[3]
      files[4..5].each do |file|
        # expect file name to come later (alphabetically) than last_file's name
        expect(file.name > last_file.name).to be true

        # set last_file to current file for next comparison
        last_file = file
      end
    end
  end

  describe '#sort_order_for_files' do
    subject(:method)  { sort_order_for_files(file) }
    let(:file)        { build :file, name: 'File Name' }

    it { is_expected.to be_an Array }

    context 'when file is directory' do
      before { allow(file).to receive(:directory?).and_return true }
      it { is_expected.to eq [0, 'File Name'] }
    end

    context 'when file is not directory' do
      before { allow(file).to receive(:directory?).and_return false }
      it { is_expected.to eq [1, 'File Name'] }
    end
  end

  describe '#type_of_file(file)' do
    subject(:method)  { type_of_file(file) }
    let(:file)        { build :file, mime_type: mime_type }

    context 'when mime type is folder' do
      let(:mime_type) { 'application/vnd.google-apps.folder' }
      it              { is_expected.to eq :folder }
    end

    context 'when mime type is document' do
      let(:mime_type) { 'application/vnd.google-apps.document' }
      it              { is_expected.to eq :document }
    end

    context 'when mime type is spreadsheet' do
      let(:mime_type) { 'application/vnd.google-apps.spreadsheet' }
      it              { is_expected.to eq :spreadsheet }
    end

    context 'when mime type is presentation' do
      let(:mime_type) { 'application/vnd.google-apps.presentation' }
      it              { is_expected.to eq :presentation }
    end

    context 'when mime type is drawing' do
      let(:mime_type) { 'application/vnd.google-apps.drawing' }
      it              { is_expected.to eq :drawing }
    end

    context 'when mime type is form' do
      let(:mime_type) { 'application/vnd.google-apps.form' }
      it              { is_expected.to eq :form }
    end

    context 'when mime type is anything else' do
      let(:mime_type) { 'some-imaginary-mime-type' }
      it              { is_expected.to eq :other }
    end

    context 'when mime type is empty' do
      let(:mime_type) { '' }
      it              { is_expected.to eq nil }
    end
  end
end

# frozen_string_literal: true

RSpec.describe FileHelper, type: :helper do
  describe '#external_link_for_file(file)' do
    subject(:method)  { helper.external_link_for_file(file) }
    let(:mime_type)   { 'abc' }
    let(:file)        { build :file, id: 'FILE-ID', mime_type: mime_type }

    context 'when mime type is folder' do
      before { allow(helper).to receive(:file_type).and_return :folder }
      it { is_expected.to eq 'https://drive.google.com/drive/folders/FILE-ID' }
    end

    context 'when mime type is document' do
      before { allow(helper).to receive(:file_type).and_return :document }
      it { is_expected.to eq 'https://docs.google.com/document/d/FILE-ID' }
    end

    context 'when mime type is spreadsheet' do
      before { allow(helper).to receive(:file_type).and_return :spreadsheet }
      it { is_expected.to eq 'https://docs.google.com/spreadsheets/d/FILE-ID' }
    end

    context 'when mime type is presentation' do
      before { allow(helper).to receive(:file_type).and_return :presentation }
      it { is_expected.to eq 'https://docs.google.com/presentation/d/FILE-ID' }
    end

    context 'when mime type is drawing' do
      before { allow(helper).to receive(:file_type).and_return :drawing }
      it { is_expected.to eq 'https://docs.google.com/drawings/d/FILE-ID' }
    end

    context 'when mime type is form' do
      before { allow(helper).to receive(:file_type).and_return :form }
      it { is_expected.to eq 'https://docs.google.com/forms/d/FILE-ID' }
    end

    context 'when mime type is anything else' do
      before { allow(helper).to receive(:file_type).and_return :other }
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
      before  { allow(helper).to receive(:file_type).and_return :folder }
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
        # expect file name to come later alphabetically) than last_file's name
        expect(file.name > last_file.name).to be true

        # set last_file to current file for next comparison
        last_file = file
      end

      last_file = files[3]
      files[4..5].each do |file|
        # expect file name to come later alphabetically) than last_file's name
        expect(file.name > last_file.name).to be true

        # set last_file to current file for next comparison
        last_file = file
      end
    end
  end

  describe '#file_type(file)' do
    subject(:method)  { file_type(file) }
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

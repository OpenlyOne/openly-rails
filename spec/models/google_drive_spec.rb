# frozen_string_literal: true

require 'googleauth'
require 'googleauth/stores/file_token_store'
GoogleDrive.initialize

RSpec.describe GoogleDrive, type: :model do
  describe '.list_files_in_folder(id_of_folder)' do
    subject(:method)    { GoogleDrive.list_files_in_folder(id_of_folder) }
    let(:id_of_folder)  { '1_T9Pw8YGc0y5iWOSX-90SzQ1CTUGFmKR' }

    it 'returns an array of files' do
      subject.each do |file|
        expect(file).to be_a Google::Apis::DriveV3::File
      end
    end

    it 'contains two files' do
      expect(subject.count).to eq 2
    end

    it 'contains a Google Doc' do
      file = subject.find do |f|
        f.id == '1uRT5v2xaAYaL41Fv9nYf3f85iadX2A-KAIEQIFPzKNY'
      end

      expect(file.name).to eq 'A Google Doc'
      expect(file.mime_type).to eq 'application/vnd.google-apps.document'
    end

    it 'contains a Google Sheet' do
      file = subject.find do |f|
        f.id == '1te4r398aV4rAYCtZaaTdKw_rMCQ4ExDHovQNVT54v2o'
      end

      expect(file.name).to eq 'A Spreadsheet'
      expect(file.mime_type).to eq 'application/vnd.google-apps.spreadsheet'
    end
  end
end

# frozen_string_literal: true

RSpec.describe Project::Setup, type: :model do
  subject(:setup) { build_stubbed :project_setup }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'aliases' do
    it { is_expected.to respond_to(:begin) }
  end

  describe 'attributes' do
    it { is_expected.to respond_to(:link) }
    it { is_expected.to respond_to(:link=) }
  end

  describe 'delegations' do
    it { is_expected.to delegate_method(:root_folder).to(:project) }
    it { is_expected.to respond_to(:root_folder=) }
  end

  describe 'callbacks' do
    subject(:setup) { build :project_setup }
    after           { setup.save }

    it { is_expected.to receive(:set_root_and_import_files) }
  end

  describe 'validations', :delayed_job do
    subject(:setup) { build :project_setup }

    it do
      is_expected
        .to validate_uniqueness_of(:project_id)
        .with_message('has already been set up')
    end
  end

  describe '#id_from_link' do
    subject(:id)  { setup.send :id_from_link }
    before        { setup.link = link }

    let(:link)    { 'https://drive.google.com/drive/folders/ID-FROM-LINK' }
    it            { is_expected.to eq 'ID-FROM-LINK' }

    context 'when link is not a folder link' do
      let(:link)  { 'https://docs.google.com/drawings/d/ID-FROM-LINK' }
      it          { is_expected.to be nil }
    end
  end

  describe '#set_root_folder' do
    subject(:set_root)  { setup.send :set_root_folder }
    let(:root_folder)   { instance_double FileResources::GoogleDrive }

    before do
      allow(setup).to receive(:id_from_link)
      allow(setup).to receive(:root_folder=)
      allow(FileResources::GoogleDrive).to receive(:find_or_initialize_by)
      allow(setup).to receive(:root_folder).and_return root_folder
    end

    context 'when root folder is a new record' do
      before { allow(root_folder).to receive(:new_record?).and_return true }

      it 'calls #pull on root folder' do
        expect(root_folder).to receive(:pull)
        set_root
      end
    end
  end
end

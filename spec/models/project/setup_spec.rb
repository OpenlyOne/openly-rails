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
    context 'after create' do
      subject(:setup) { build :project_setup, :with_link }
      after           { setup.save(validate: false) }

      it { is_expected.to receive(:set_root_and_import_files) }
    end

    context 'after destroy', :delayed_job do
      subject(:setup) { create :project_setup, :with_link }
      after           { setup.destroy }

      it { is_expected.to receive(:destroy_all_jobs) }
    end
  end

  describe 'validations', :delayed_job do
    subject(:setup) { build :project_setup }

    it do
      is_expected
        .to validate_uniqueness_of(:project_id)
        .with_message('has already been set up')
    end
  end

  describe '#check_if_complete' do
    let(:persisted) { false }
    let(:jobs)      { %w[j1 j2 j3] }

    before do
      allow(setup).to receive(:persisted?).and_return persisted
      allow(setup).to receive(:folder_import_jobs).and_return jobs
      allow(setup).to receive(:complete)
    end

    after { setup.check_if_complete }

    it { is_expected.not_to receive(:complete) }

    context 'when persisted' do
      let(:persisted) { true }
      it { is_expected.not_to receive(:complete) }
    end

    context 'when no folder import jobs' do
      let(:jobs) { [] }
      it { is_expected.not_to receive(:complete) }
    end

    context 'when persisted and no folder import jobs' do
      let(:persisted) { true }
      let(:jobs)      { [] }
      it              { is_expected.to receive(:complete) }
    end
  end

  describe '#complete' do
    before do
      allow(setup).to receive(:create_origin_revision_in_project)
      allow(setup).to receive(:update)
    end

    after { setup.send :complete }

    it { is_expected.to receive(:create_origin_revision_in_project) }
    it { is_expected.to receive(:update).with(is_completed: true) }
  end

  describe '#create_origin_revision_in_project' do
    let(:revision) { instance_double Revision }

    before do
      project = instance_double Project
      allow(setup).to receive(:project).and_return project
      allow(project).to receive(:owner).and_return 'author'
      allow(project)
        .to receive_message_chain(:revisions, :create_draft_and_commit_files!)
        .with('author')
        .and_return revision
      allow(revision).to receive(:update)
    end

    after { setup.send :create_origin_revision_in_project }

    it 'publishes revision' do
      expect(revision)
        .to receive(:update)
        .with(is_published: true, title: 'Import Files',
              summary: 'Import Files from Google Drive.')
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

  describe '#file' do
    subject(:get_file)  { setup.send :file }
    let(:file)          { instance_double FileResources::GoogleDrive }
    let(:is_new_record) { false }

    before do
      allow(setup).to receive(:id_from_link).and_return 'FILE-ID'
      allow(FileResources::GoogleDrive)
        .to receive(:find_or_initialize_by)
        .with(external_id: 'FILE-ID')
        .and_return file
      allow(file).to receive(:new_record?).and_return is_new_record
      allow(file).to receive(:pull)
    end

    it { is_expected.to eq file }

    context 'when file is a new record' do
      let(:is_new_record) { true }

      it { is_expected.to eq file }

      it 'calls #pull on file' do
        expect(file).to receive(:pull)
        get_file
      end
    end
  end
end

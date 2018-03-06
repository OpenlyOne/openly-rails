# frozen_string_literal: true

require 'models/shared_examples/having_version_control.rb'

RSpec.describe Project, type: :model do
  subject(:project) { build(:project) }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  it_should_behave_like 'having version control' do
    subject(:object) { build(:project) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:owner) }
    it do
      is_expected
        .to have_and_belong_to_many(:collaborators)
        .class_name('Profiles::User').validate(false)
    end
    it do
      is_expected
        .to have_one(:staged_root_folder)
        .conditions(is_root: true)
        .class_name('StagedFile')
        .dependent(:delete)
    end
    it do
      is_expected
        .to have_one(:root_folder)
        .class_name('FileResource')
        .through(:staged_root_folder)
        .source(:file_resource)
        .dependent(false)
    end
    it { is_expected.to have_many(:staged_files).dependent(:destroy) }
    it do
      is_expected
        .to have_many(:file_resources_in_stage)
        .class_name('FileResource')
        .through(:staged_files)
        .source(:file_resource)
        .dependent(false)
    end
    it do
      is_expected
        .to have_many(:staged_non_root_files)
        .conditions(is_root: false)
        .class_name('StagedFile')
        .dependent(false)
    end
    it do
      is_expected
        .to have_many(:non_root_file_resources_in_stage)
        .class_name('FileResource')
        .through(:staged_non_root_files)
        .source(:file_resource)
        .dependent(false)
    end
    it do
      is_expected
        .to have_many(:non_root_file_snapshots_in_stage)
        .class_name('FileResource::Snapshot')
        .through(:non_root_file_resources_in_stage)
        .source(:current_snapshot)
        .dependent(false)
    end
    it do
      is_expected
        .to have_many(:all_revisions)
        .class_name('Revision')
        .dependent(:destroy)
    end
    it do
      is_expected
        .to have_many(:revisions)
        .conditions(is_published: true)
        .dependent(false)
    end
  end

  describe 'attributes' do
    it { is_expected.to have_readonly_attribute(:owner_id) }
    it { is_expected.to have_readonly_attribute(:owner_type) }
    it { is_expected.to have_readonly_attribute(:owner_type) }
  end

  describe 'callbacks' do
    context 'before validation' do
      subject(:project) { build(:project, slug: '') }
      after { project.valid? }

      it { is_expected.to receive(:generate_slug_from_title) }

      context 'when title is nil' do
        subject(:project) { build(:project, title: nil) }
        it { is_expected.not_to receive(:generate_slug_from_title) }
      end

      context 'when slug is set' do
        subject(:project) { build(:project, slug: 'project-slug') }
        it { is_expected.not_to receive(:generate_slug_from_title) }
      end
    end

    context 'after save' do
      subject(:project)     { build(:project) }
      let(:link_to_folder)  { 'https://drive.google.com/drive/folders/test' }

      before do
        allow(subject).to receive(:import_google_drive_folder)
        allow(subject).to receive(:link_to_google_drive_is_accessible_folder)
      end

      context 'when import_google_drive_folder_on_save is true' do
        before do
          project.import_google_drive_folder_on_save = true
          project.link_to_google_drive_folder = link_to_folder
        end
        after { project.save }
        it    { is_expected.to receive(:import_google_drive_folder) }
      end

      context 'when import_google_drive_folder_on_save was true' do
        before do
          project.import_google_drive_folder_on_save = true
          project.link_to_google_drive_folder = link_to_folder
          project.save
        end
        it { expect(project.import_google_drive_folder_on_save).to be false }
      end
    end
  end

  describe 'validations' do
    it do
      is_expected.to validate_presence_of(:owner).with_message 'must exist'
    end
    it do
      is_expected
        .to validate_inclusion_of(:owner_type).in_array %w[Profiles::Base]
    end
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_most(50) }

    context 'when validating slug' do
      # Test does not work with polymorphic associations, use custom test below
      # instead
      # it do
      #   is_expected
      #     .to validate_uniqueness_of(:slug)
      #     .case_insensitive
      #     .scoped_to(:owner_type, :owner_id)
      # end
      context 'uniqueness of slug scoped to owner type + ID' do
        let!(:first_project)      { create :project, slug: slug, owner: owner }
        let(:slug)  { 'my-slug' }
        let(:owner) { create(:user) }

        context 'when owner type is identical but ID is different' do
          subject(:second_project)  { build :project, slug: slug }
          before                    { second_project.valid? }
          it 'does not add a :slug error' do
            expect(second_project.errors[:slug])
              .not_to include 'has already been taken'
          end
        end

        context 'when owner ID is identical but type is different' do
          subject(:second_project) { build :project, slug: slug, owner: owner }
          before do
            second_project.owner_type = 'Project'
            second_project.valid?
          end
          it 'does not add a :slug error' do
            expect(second_project.errors[:slug])
              .not_to include 'has already been taken'
          end
        end

        context 'when owner ID + type are identical' do
          subject(:second_project)  { build :project, slug: slug, owner: owner }
          before                    { second_project.valid? }
          it 'adds a :slug error' do
            expect(second_project.errors[:slug])
              .to include 'has already been taken'
          end
        end
      end

      it do
        subject.title = nil # set title to nil to prevent slug auto-generation
        is_expected.to validate_presence_of(:slug)
      end
      it { is_expected.to validate_length_of(:slug).is_at_most(50) }

      it 'special characters are invalid' do
        project.slug = 'a*<>$@/r?!'
        is_expected.to be_invalid
      end

      it 'a dash at the beginning is invalid' do
        project.slug = '-' + project.slug
        is_expected.to be_invalid
      end

      it 'a dash at the end is invalid' do
        project.slug += '-'
        is_expected.to be_invalid
      end

      it "must not be 'edit'" do
        project.slug = 'edit'
        is_expected.to be_invalid
      end
    end

    context 'when import_google_drive_folder_on_save = true' do
      let(:file)      { instance_double Google::Apis::DriveV3::File }
      let(:mime_type) { Providers::GoogleDrive::MimeType.folder }
      let(:link)      { 'https://drive.google.com/drive/folders/test' }

      before { allow(GoogleDrive).to receive(:get_file).and_return file }
      before { allow(file).to receive(:mime_type).and_return(mime_type) }
      before { project.import_google_drive_folder_on_save = true }
      before { project.link_to_google_drive_folder = link }
      before { project.valid? }
      context 'when link to google drive folder is valid' do
        it 'does not add an error' do
          expect(project.errors[:link_to_google_drive_folder].size)
            .to eq 0
        end
      end
      context 'when link to google drive folder is invalid' do
        let(:link) { 'https://invalid-folder-link' }

        it 'adds an error' do
          expect(project.errors[:link_to_google_drive_folder])
            .to include 'appears not to be a valid Google Drive link'
        end
      end
      context 'when link to google drive folder is inaccessible' do
        before do
          allow(GoogleDrive)
            .to receive(:get_file).and_raise(Google::Apis::ClientError, 'error')
        end

        it 'adds an error' do
          project.valid?

          expect(project.errors[:link_to_google_drive_folder])
            .to include 'appears to be inaccessible. Have you shared the '\
                        'resource with '\
                        "#{Settings.google_drive_tracking_account}?"
        end
      end
      context 'when link to google drive folder is not a folder' do
        let(:mime_type) { Providers::GoogleDrive::MimeType.document }

        it 'adds an error' do
          expect(project.errors[:link_to_google_drive_folder])
            .to include 'appears not to be a Google Drive folder'
        end
      end
    end
  end

  describe '.find' do
    let!(:project) { create(:project) }
    subject(:method) { Project.find(project.owner.to_param, project.slug) }

    it 'finds project by profile handle and slug' do
      is_expected.to eq project
    end

    context 'when profile does not exist' do
      before { project.owner.destroy }
      it { expect { method }.to raise_error ActiveRecord::RecordNotFound }
    end

    context 'when project does not exist' do
      before { project.destroy }
      it { expect { method }.to raise_error ActiveRecord::RecordNotFound }
    end

    context 'when project slug is not passed' do
      subject(:method) { Project.find(project.id) }

      it 'finds project by ID' do
        is_expected.to eq project
      end
    end
  end

  describe '.repository_folder_path' do
    subject(:method) { Project.repository_folder_path }

    it do
      is_expected.to eq(
        Rails.root.join(
          Settings.file_storage,
          'projects'
        ).cleanpath.to_s
      )
    end
  end

  describe 'revisions#create_draft_and_commit_files!' do
    subject(:method) do
      project.revisions.create_draft_and_commit_files!('author')
    end

    it 'calls Revision#create_draft_and_commit_files_for_project!' do
      expect(Revision)
        .to receive(:create_draft_and_commit_files_for_project!)
        .with(project, 'author')
      method
    end
  end

  describe '#import_google_drive_folder', isolated_unit_test: true do
    subject(:method)    { project.send :import_google_drive_folder }
    let(:project)       { build_stubbed(:project) }
    let(:file)          { instance_double Google::Apis::DriveV3::File }
    let(:mime_type)     { Providers::GoogleDrive::MimeType.folder }
    let(:root_folder)   { instance_double FileResource }

    before do
      allow(project).to receive(:google_drive_folder_id).and_return 'folder-id'
      allow(project).to receive(:root_folder=)
      allow(FileResources::GoogleDrive)
        .to receive(:find_or_initialize_by)
        .with(external_id: 'folder-id')
        .and_return(root_folder)
      allow(root_folder).to receive(:pull)
      allow(project).to receive(:root_folder).and_return root_folder
      allow(root_folder).to receive(:id).and_return 'the-id'
      allow(FolderImportJob).to receive(:perform_later)
    end

    it 'calls #pull on root folder' do
      expect(root_folder).to receive(:pull)
      subject
    end

    it 'sets root folder' do
      expect(project).to receive(:root_folder=).with(root_folder)
      subject
    end

    it 'creates a FolderImportJob' do
      expect(FolderImportJob).to receive(:perform_later)
        .with(reference: project, file_resource_id: 'the-id')
      subject
    end

    context 'when error is raised' do
      let(:staged_root_folder) { instance_double StagedFile }

      before do
        allow(project).to receive(:root_folder).and_raise StandardError
        allow(project)
          .to receive(:staged_root_folder).and_return staged_root_folder
        allow(staged_root_folder).to receive(:destroy)
      end

      it 'calls #destroy on staged root folder' do
        expect(staged_root_folder).to receive(:destroy)
        expect { subject }.to raise_error StandardError
      end

      it 're-raises the error' do
        expect { subject }.to raise_error StandardError
      end
    end
  end

  describe '#tag_list' do
    subject(:method)  { project.tag_list }
    let(:tags)        { %w[one two three four] }
    before            { project.tags = tags }

    it 'returns tags joined by comma' do
      is_expected.to eq 'one, two, three, four'
    end
  end

  describe '#tag_list=' do
    subject(:method)  { project.tag_list = tag_list }
    let(:tag_list)    { 'one,two,three,four' }

    it 'splits tag list into tags' do
      method
      expect(project.tags).to eq %w[one two three four]
    end

    context 'when list contains whitespace around tag delimiter' do
      let(:tag_list) { 'one   ,  two, three   ,four' }

      it 'strips whitespace from beginning and end of tag' do
        method
        expect(project.tags).to eq %w[one two three four]
      end
    end

    context 'when list contains multiple whitespaces within tag' do
      let(:tag_list) { 'my  awesome  tag, other    tag' }

      it 'squishes whitespace to single space' do
        method
        expect(project.tags).to eq ['my awesome tag', 'other tag']
      end
    end

    context 'when list contains empty tags' do
      let(:tag_list) { 'my tag, , other tag' }

      it 'ignores the empty tags' do
        method
        expect(project.tags).to eq ['my tag', 'other tag']
      end
    end
  end

  describe '#title=' do
    it 'strips whitespace' do
      project.title = '   lots of whitespace     '
      expect(project.title).to eq 'lots of whitespace'
    end

    it 'leaves nil unchanged' do
      project.title = nil
      expect(project.title).to eq nil
    end
  end

  describe '#to_param' do
    subject(:project) { build_stubbed(:project) }

    it 'returns the slug' do
      expect(project.to_param).to eq project.slug
    end

    context 'if slug is changed' do
      before { project.slug = 'new-slug' }

      it 'returns the slug before change' do
        expect(project.to_param).to eq project.slug_was
      end
    end
  end

  describe '#generate_slug_from_title' do
    it 'removes non-alphanumeric characters' do
      project = build(:project, title: 'Project!?@')
      project.send(:generate_slug_from_title)
      expect(project.slug).to eq 'project'
    end

    it 'strips extra whitespace' do
      project = build(:project, title: 'Project#1:)')
      project.send(:generate_slug_from_title)
      expect(project.slug).to eq 'project1'
    end

    it 'replaces spaces with dashes' do
      project = build(:project, title: 'My New Project')
      project.send(:generate_slug_from_title)
      expect(project.slug).to eq 'my-new-project'
    end

    it 'downcases the slug' do
      project = build(:project, title: 'PRojECT UpperCASE #$?')
      project.send(:generate_slug_from_title)
      expect(project.slug).to eq 'project-uppercase'
    end
  end

  describe '#repository_file_path' do
    subject(:repo_path) { project.send(:repository_file_path) }
    let(:project)       { build_stubbed(:project) }

    it do
      is_expected.to eq(
        Rails.root.join(
          Settings.file_storage,
          'projects',
          project.id_in_database.to_s
        ).cleanpath.to_s
      )
    end

    context 'when id_in_database is nil' do
      before { allow(project).to receive(:id_in_database).and_return(nil) }
      it { is_expected.to be nil }
    end
  end
end

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

  describe '#import_google_drive_folder' do
    subject(:method)    { project.save }
    let(:id_of_folder)  { 'folder-id' }
    let(:project)       { create(:project) }
    let(:file)          { instance_double Google::Apis::DriveV3::File }
    let(:mime_type)     { Providers::GoogleDrive::MimeType.folder }

    before do
      allow(GoogleDrive).to receive(:get_file).and_return(file)
      allow(file).to receive(:mime_type).and_return(mime_type)
      allow(file)
        .to receive(:to_h)
        .and_return(id: id_of_folder, mime_type: mime_type)
    end

    before do
      allow(FolderImportJob).to receive(:perform_later)
    end

    before do
      project.instance_variable_set(:@google_drive_folder_id, id_of_folder)
      project.import_google_drive_folder_on_save = true
    end

    it 'creates a root folder' do
      subject
      expect(project.reload.files.root).to be_a VersionControl::File
    end

    it 'creates a FolderImportJob' do
      expect(FolderImportJob).to receive(:perform_later)
        .with(
          reference: project,
          folder_id: id_of_folder
        )
      subject
    end

    context 'when save fails' do
      before { allow(project).to receive(:save).and_return(false) }

      it 'does not persist root folder' do
        subject
        expect(project.reload.files.root).to be nil
      end

      it 'does not start a FolderImportJob' do
        expect(FolderImportJob).not_to receive(:perform_later)
        subject
      end
    end

    context 'when root folder already exists' do
      before { create :file, :root, repository: project.repository }
      before { project.reload }

      it { is_expected.to be false }

      it 'does not persist changes to project' do
        project.title = 'My New Title'
        method
        expect(project.reload.title).not_to eq 'My New Title'
      end
    end

    context 'when any error occurs' do
      before do
        allow(FolderImportJob).to receive(:perform_later).and_raise('error')
      end

      it 'does not persist root folder' do
        expect { method }.to raise_error RuntimeError
        expect(project.reload.files.root).to be nil
      end

      it 'does not persist changes to project' do
        project.title = 'My New Title'
        expect { method }.to raise_error RuntimeError
        expect(project.reload.title).not_to eq 'My New Title'
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

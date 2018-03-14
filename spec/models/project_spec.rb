# frozen_string_literal: true

RSpec.describe Project, type: :model do
  subject(:project) { build(:project) }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  describe 'associations' do
    it { is_expected.to belong_to(:owner).class_name('Profiles::Base') }
    it do
      is_expected
        .to have_and_belong_to_many(:collaborators)
        .class_name('Profiles::User').validate(false)
    end
    it { is_expected.to have_one(:setup).dependent(:destroy) }
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

  describe 'delegations' do
    it do
      is_expected
        .to delegate_method(:in_progress?)
        .to(:setup)
        .with_prefix
    end
    it do
      is_expected
        .to delegate_method(:completed?)
        .to(:setup)
        .with_prefix
    end
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
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_most(50) }

    context 'when validating slug' do
      it do
        is_expected
          .to validate_uniqueness_of(:slug)
          .scoped_to(:owner_id)
          .case_insensitive
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

  describe '#setup_not_started?' do
    subject(:setup_started) { project.setup_not_started? }
    let(:not_started)       { false }
    let(:setup)             { instance_double Project::Setup }

    before do
      allow(project).to receive(:setup).and_return setup
      allow(setup).to receive(:not_started?).and_return(not_started) if setup
    end

    context 'when setup is nil' do
      let(:setup) { nil }
      it          { is_expected.to eq true }
    end

    context 'when setup is present' do
      let(:not_started) { 'value' }
      it                { is_expected.to eq 'value' }
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
end

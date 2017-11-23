# frozen_string_literal: true

RSpec.describe Project, type: :model do
  subject(:project) { build(:project) }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  describe 'associations' do
    it { is_expected.to belong_to(:owner) }
    it do
      is_expected.to(
        have_one(:root_folder).class_name('FileItems::Folder')
                              .dependent(:destroy)
      )
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

    context 'around save' do
      subject(:project) { build(:project) }
      after { project.save }

      context 'when import_google_drive_folder_on_save is true' do
        before do
          if ENV['MOCK_GOOGLE_DRIVE_REQUESTS'] == 'true'
            mock_google_drive_requests
          end
        end
        before do
          project.import_google_drive_folder_on_save = true
          project.link_to_google_drive_folder =
            Settings.google_drive_test_folder
        end
        it { is_expected.to receive(:import_google_drive_folder) }
      end
    end

    context 'after save' do
      subject(:project) { build(:project) }

      context 'when import_google_drive_folder_on_save was true' do
        before do
          if ENV['MOCK_GOOGLE_DRIVE_REQUESTS'] == 'true'
            mock_google_drive_requests
          end
        end
        before do
          allow(project).to receive(:import_google_drive_folder)
          project.import_google_drive_folder_on_save = true
          project.link_to_google_drive_folder =
            Settings.google_drive_test_folder
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
    end

    context 'when import_google_drive_folder_on_save = true' do
      before do
        if ENV['MOCK_GOOGLE_DRIVE_REQUESTS'] == 'true'
          mock_google_drive_requests
        end
      end
      before { project.import_google_drive_folder_on_save = true }
      before { project.link_to_google_drive_folder = link }
      before { project.valid? }
      context 'when link to google drive folder is valid' do
        let(:link) { Settings.google_drive_test_folder }
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
        let(:link) do
          'https://drive.google.com/drive/u/1/folders/' \
          '0B4149cktxhmPV0pLQjRVRy1rTEk'
        end
        it 'adds an error' do
          expect(project.errors[:link_to_google_drive_folder])
            .to include 'appears to be inaccessible. Have you shared the '\
                        'resource with '\
                        "#{Settings.google_drive_tracking_account}?"
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

  describe '#import_google_drive_folder' do
    before do
      mock_google_drive_requests if ENV['MOCK_GOOGLE_DRIVE_REQUESTS'] == 'true'
    end
    before do
      project.instance_variable_set(:@google_drive_folder_id, id_of_folder)
    end
    subject(:method) do
      project.send(:import_google_drive_folder) { project.save }
    end
    let(:id_of_folder)  { Settings.google_drive_test_folder_id }
    let(:project)       { create(:project) }

    it 'creates a root folder' do
      subject
      expect(project.root_folder).to be_persisted
    end

    it 'creates a FolderImportJob' do
      expect(FolderImportJob).to receive(:perform_later)
        .with(
          reference: project,
          folder_id: kind_of(Numeric)
        )
      subject
    end

    context 'when save fails' do
      before { allow(project).to receive(:save).and_return(false) }

      it 'does not persist root folder' do
        subject
        expect(project.root_folder).not_to be_persisted
      end

      it 'does not start a FolderImportJob' do
        expect(FolderImportJob).not_to receive(:perform_later)
        subject
      end
    end

    context 'when root folder already exists' do
      before { create :file_items_folder, project: project, parent: nil }
      before { project.reload }

      it 'raises an error' do
        expect { project.send(:import_google_drive_folder) }
          .to raise_error "Project #{project.id}: Root folder already exists"
      end
    end
  end

  describe '#link_to_google_drive_folder' do
    subject(:method) { project.link_to_google_drive_folder }

    context 'when a root folder exists' do
      before do
        create :file_items_folder, project: project, name: 'root',
                                   google_drive_id: folder_id, parent: nil
      end
      let(:folder_id) { Settings.google_drive_test_folder_id }

      it 'returns its link' do
        is_expected.to eq 'https://drive.google.com/drive/folders/'\
          "#{folder_id}"
      end
    end

    context 'when root folder does not exist' do
      it { is_expected.to be nil }
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

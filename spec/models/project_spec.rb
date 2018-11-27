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
        .to belong_to(:master_branch)
        .class_name('VCS::Branch')
        .dependent(:destroy)
        .optional
    end
    it do
      is_expected
        .to belong_to(:repository)
        .class_name('VCS::Repository')
        .dependent(:destroy)
        .optional
    end
    it do
      is_expected
        .to have_many(:revisions)
        .class_name('VCS::Commit')
        .through(:master_branch)
        .source(:commits)
        .dependent(false)
    end
    it do
      is_expected
        .to have_one(:archive)
        .class_name('VCS::Archive')
        .through(:repository)
        .dependent(false)
    end

    it { is_expected.to have_many(:contributions).dependent(:destroy) }

    context 'when adding collaborator' do
      let(:collaborator) { create :user }

      before do
        allow(project).to receive(:grant_read_access_to_archive)
        project.collaborators << collaborator
      end

      it do
        is_expected
          .to have_received(:grant_read_access_to_archive).with(collaborator)
      end
    end

    context 'when removing collaborator' do
      let(:collaborator) { create :user }

      before do
        allow(project).to receive(:revoke_access_to_archive)
        project.collaborators << collaborator
        project.collaborators.delete(collaborator)
      end

      it do
        is_expected
          .to have_received(:revoke_access_to_archive).with(collaborator)
      end
    end
  end

  describe 'attributes' do
    it { is_expected.to have_readonly_attribute(:owner_id) }
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
    it { is_expected.to delegate_method(:branches).to(:repository) }
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

    context 'before create' do
      subject(:project) { build(:project) }

      before do
        allow(project).to receive(:create_repository)
        allow(project).to receive(:create_master_branch_with_repository)
        allow(project).to receive(:setup_archive)
        before_save_hook if defined?(before_save_hook)
        project.save
      end

      it { is_expected.to have_received(:create_repository) }
      it { is_expected.to have_received(:create_master_branch_with_repository) }

      context 'when repository is present' do
        let(:before_save_hook)  { project.repository = VCS::Repository.new }

        it { is_expected.not_to have_received(:create_repository) }
      end

      context 'when master_branch is present' do
        let(:before_save_hook) { project.master_branch = VCS::Branch.new }

        it do
          is_expected
            .not_to have_received(:create_master_branch_with_repository)
        end
      end
    end

    context 'after create' do
      subject(:project) { build(:project) }

      before do
        allow(project).to receive(:setup_archive)
        before_save_hook if defined?(before_save_hook)
        project.save
      end

      it { is_expected.to have_received(:setup_archive) }

      context 'when skip_archive_setup = true' do
        let(:before_save_hook) { project.skip_archive_setup = true }

        it { is_expected.not_to have_received(:setup_archive) }
      end
    end

    context 'before update' do
      let(:project) do
        create(:project, :skip_archive_setup, is_public: was_public)
      end

      before do
        allow(project).to receive(:make_archive_public)
        allow(project).to receive(:make_archive_private)
        project.update(is_public: is_public)
      end

      context 'when public -> public' do
        let(:was_public)  { true }
        let(:is_public)   { true }

        it { is_expected.not_to have_received(:make_archive_public) }
        it { is_expected.not_to have_received(:make_archive_private) }
      end

      context 'when public -> private' do
        let(:was_public)  { true }
        let(:is_public)   { false }

        it { is_expected.not_to have_received(:make_archive_public) }
        it { is_expected.to have_received(:make_archive_private) }
      end

      context 'when private -> private' do
        let(:was_public)  { false }
        let(:is_public)   { false }

        it { is_expected.not_to have_received(:make_archive_public) }
        it { is_expected.not_to have_received(:make_archive_private) }
      end

      context 'when private -> public' do
        let(:was_public)  { false }
        let(:is_public)   { true }

        it { is_expected.to have_received(:make_archive_public) }
        it { is_expected.not_to have_received(:make_archive_private) }
      end
    end
  end

  describe 'validations' do
    before { allow(project).to receive(:setup_archive) }

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

  describe '#make_archive_private' do
    subject(:make_archive_private) { project.send(:make_archive_private) }

    let(:archive) { instance_double VCS::Archive }

    before do
      allow(project).to receive(:archive).and_return archive
      allow(archive).to receive(:remove_public_access) if archive
    end

    it do
      make_archive_private
      expect(archive).to have_received(:remove_public_access)
    end

    context 'when archive does not exist' do
      let(:archive) { nil }

      it { expect { make_archive_private }.not_to raise_error }
    end
  end

  describe '#make_archive_public' do
    subject(:make_archive_public) { project.send(:make_archive_public) }

    let(:archive) { instance_double VCS::Archive }

    before do
      allow(project).to receive(:archive).and_return archive
      allow(archive).to receive(:grant_public_access) if archive
    end

    it do
      make_archive_public
      expect(archive).to have_received(:grant_public_access)
    end

    context 'when archive does not exist' do
      let(:archive) { nil }

      it { expect { make_archive_public }.not_to raise_error }
    end
  end

  describe '#grant_read_access_to_archive(collaborator)' do
    subject(:grant_access) do
      project.send(:grant_read_access_to_archive, collaborator)
    end

    let(:collaborator)  { instance_double Profiles::User }
    let(:account)       { instance_double Account }
    let(:archive)       { instance_double VCS::Archive }

    before do
      allow(collaborator).to receive(:account).and_return account
      allow(account).to receive(:email).and_return 'email@email.com'
      allow(project).to receive(:archive).and_return archive
      allow(archive).to receive(:grant_read_access_to) if archive
    end

    it do
      grant_access
      expect(archive)
        .to have_received(:grant_read_access_to).with('email@email.com')
    end

    context 'when archive does not exist' do
      let(:archive) { nil }

      it { expect { grant_access }.not_to raise_error }
    end
  end

  describe '#revoke_access_to_archive(collaborator)' do
    subject(:revoke_acess) do
      project.send(:revoke_access_to_archive, collaborator)
    end

    let(:collaborator)  { instance_double Profiles::User }
    let(:account)       { instance_double Account }
    let(:archive)       { instance_double VCS::Archive }

    before do
      allow(collaborator).to receive(:account).and_return account
      allow(account).to receive(:email).and_return 'email@email.com'
      allow(project).to receive(:archive).and_return archive
      allow(archive).to receive(:revoke_access_from) if archive
    end

    it do
      revoke_acess
      expect(archive)
        .to have_received(:revoke_access_from).with('email@email.com')
    end

    context 'when archive does not exist' do
      let(:archive) { nil }

      it { expect { revoke_acess }.not_to raise_error }
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

  describe '#setup_archive' do
    subject(:project) { build_stubbed(:project) }

    let(:archive)         { instance_double VCS::Archive }
    let(:repository)      { instance_double VCS::Repository }
    let(:setup_completed) { false }

    before do
      allow(project).to receive(:repository).and_return repository
      allow(project).to receive(:repository_archive).and_return(archive)
      allow(archive).to receive(:setup)
      allow(archive).to receive(:setup_completed?).and_return setup_completed
      allow(archive).to receive(:grant_public_access)
      allow(archive).to receive(:save)

      project.send(:setup_archive)
    end

    it 'builds archive, sets it up, and saves' do
      expect(archive).to have_received(:setup)
      expect(archive).to have_received(:save)
    end

    it 'does not grant public access to the archive' do
      expect(archive).not_to have_received(:grant_public_access)
    end

    context 'when repository is not present' do
      let(:repository) { nil }

      it 'does not call #setup' do
        expect(archive).not_to have_received(:setup)
        expect(archive).not_to have_received(:save)
      end
    end

    context 'when setup is already complete' do
      let(:setup_completed) { true }

      it 'does not call #setup' do
        expect(archive).not_to have_received(:setup)
        expect(archive).not_to have_received(:save)
      end
    end

    context 'when project is public' do
      subject(:project) { build_stubbed(:project, :public) }

      it 'makes archive publicly accessible' do
        expect(archive).to have_received(:grant_public_access)
      end
    end
  end
end

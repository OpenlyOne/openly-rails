# frozen_string_literal: true

require 'cancan/matchers'

RSpec.shared_examples 'having authorization' do |object_actions|
  object_actions.each do |action|
    it { is_expected.to be_able_to action, *object }
  end
end

RSpec.shared_examples 'not having authorization' do |object_actions|
  object_actions.each do |action|
    it { is_expected.not_to be_able_to action, *object }
  end
end

RSpec.describe Ability, type: :model do
  subject(:ability) { Ability.new(user) }
  let(:user) { create(:user) }

  context 'Project Access' do
    actions = %i[access]
    let(:object)  { project }
    let(:project) { build_stubbed(:project) }

    context 'when project is public' do
      let(:user) { nil }
      before { project.is_public = true }
      it_should_behave_like 'having authorization', actions
    end

    context 'when user is not signed in' do
      let(:user) { nil }
      it_should_behave_like 'not having authorization', actions
    end

    context 'when user is not project owner or collaborator' do
      before { project.owner = build_stubbed(:user) }
      before { project.collaborators = [] }
      it_should_behave_like 'not having authorization', actions
    end

    context 'when user is project owner' do
      before { project.owner = user }
      it_should_behave_like 'having authorization', actions
    end

    context 'when user is collaborator' do
      before { project.collaborators << user }
      it_should_behave_like 'having authorization', actions
    end
  end

  context 'Users' do
    actions = %i[manage]
    let(:object) { build_stubbed(:user) }

    context 'when user is self' do
      before { object.id = user.id }
      it_should_behave_like 'having authorization', actions
    end

    context 'when user is not self' do
      before { object.id = build_stubbed(:user).id }
      it_should_behave_like 'not having authorization', actions
    end
  end

  context 'Projects' do
    describe 'create' do
      actions = %i[create]

      let(:object) { build_stubbed(:project, :public, owner: user) }

      it_should_behave_like 'having authorization', actions

      context 'when project is not owned by user' do
        before { object.owner = build_stubbed(:user) }

        it_should_behave_like 'not having authorization', actions
      end

      context 'when project visibility has not been chosen' do
        before { object.is_public = nil }

        it_should_behave_like 'having authorization', actions
      end

      context 'when project is private' do
        before { object.is_public = false }

        context 'when user has premium account' do
          let(:user) { create(:user, :premium) }

          it_should_behave_like 'having authorization', actions
        end

        context 'when user does not have premium account' do
          let(:user) { create(:user) }

          it_should_behave_like 'not having authorization', actions
        end
      end
    end

    describe 'edit, update, destroy' do
      actions = %i[edit update destroy]
      let(:object) { build_stubbed(:project) }

      context 'when user is owner' do
        before { object.owner = user }
        it_should_behave_like 'having authorization', actions
      end

      context 'when user is not owner' do
        before { object.owner = build_stubbed(:user) }
        it_should_behave_like 'not having authorization', actions
      end
    end
  end

  context 'File in Branch' do
    actions = %i[show]
    let(:object)  { [:file_in_branch, project] }
    let(:project) { build_stubbed(:project) }

    context 'when user is project owner' do
      before { project.owner = user }
      it_should_behave_like 'having authorization', actions
    end

    context 'when user is collaborator' do
      before { project.collaborators << user }
      it_should_behave_like 'having authorization', actions
    end

    context 'when user is not project owner or collaborator' do
      before { project.owner = build_stubbed(:user) }
      before { project.collaborators = [] }
      it_should_behave_like 'not having authorization', actions
    end
  end

  describe 'Collaborators of projects' do
    actions = %i[force_sync restore_file restore_revision setup]
    let(:object)  { project }
    let(:project) { build_stubbed(:project) }

    context 'when user is project owner' do
      before { project.owner = user }
      it_should_behave_like 'having authorization', actions
    end

    context 'when user is collaborator' do
      before { project.collaborators << user }
      it_should_behave_like 'having authorization', actions
    end

    context 'when user is not project owner or collaborator' do
      before { project.owner = build_stubbed(:user) }
      before { project.collaborators = [] }
      it_should_behave_like 'not having authorization', actions
    end
  end

  context 'Revisions' do
    actions = %i[new create]
    let(:project)   { create :project, :skip_archive_setup }
    let(:revision)  { project.repository.build_revision }
    let(:object)    { [:revision, project] }

    context 'when user is project owner' do
      before { project.owner = user }
      it_should_behave_like 'having authorization', actions
    end

    context 'when user is collaborator' do
      before { project.collaborators << user }
      it_should_behave_like 'having authorization', actions
    end

    context 'when user is not project owner or collaborator' do
      before { project.owner = build_stubbed(:user) }
      before { project.collaborators = [] }
      it_should_behave_like 'not having authorization', actions
    end
  end

  context 'Contributions' do
    let(:object) { contribution }

    describe 'CRUD + reply' do
      actions = %i[new create reply]
      let(:project)       { create :project, :skip_archive_setup }
      let(:contribution)  { project.contributions.build }
      let(:user)          { build_stubbed :user }

      before do
        allow(Ability).to receive(:new).with(user).and_return ability
        allow(ability).to receive(:can?).and_call_original
        allow(ability)
          .to receive(:can?).with(:access, project).and_return can_access
      end

      context 'when user can access project' do
        let(:can_access) { true }

        it_should_behave_like 'having authorization', actions
      end

      context 'when user cannot access project' do
        let(:can_access) { false }

        it_should_behave_like 'not having authorization', actions
      end
    end

    describe 'accept' do
      actions = %i[accept]

      let(:contribution)  { build_stubbed(:contribution) }
      let(:project)       { contribution.project }

      context 'when user is project owner' do
        before { project.owner = user }
        it_should_behave_like 'having authorization', actions
      end

      context 'when user is project collaborator' do
        before { project.collaborators << user }
        it_should_behave_like 'having authorization', actions
      end

      context 'when user is not project owner or collaborator' do
        before { project.owner = build_stubbed(:user) }
        before { project.collaborators = [] }
        it_should_behave_like 'not having authorization', actions
      end
    end

    describe 'force sync' do
      actions = %i[force_sync]
      let(:contribution) { build_stubbed(:contribution) }

      context 'when user is creator' do
        before { contribution.creator = user }
        it_should_behave_like 'having authorization', actions
      end

      context 'when user is not creator' do
        before { contribution.creator = build_stubbed(:user) }
        it_should_behave_like 'not having authorization', actions
      end
    end
  end
end

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

  context 'Project files' do
    actions = %i[edit_content update_content edit_name update_name delete
                 destroy]
    let(:object)  { [build(:vc_file), project] }
    let(:project) { build_stubbed :project }
    before do
      allow_any_instance_of(Ability).to receive(:can?).and_call_original
    end

    context 'when user can edit project' do
      before do
        allow_any_instance_of(Ability)
          .to receive(:can?)
          .with(:edit, project)
          .and_return true
      end
      it_should_behave_like 'having authorization', actions
    end

    context 'when user cannot edit project' do
      before do
        allow_any_instance_of(Ability)
          .to receive(:can?)
          .with(:edit, project)
          .and_return false
      end
      it_should_behave_like 'not having authorization', actions
    end
  end
end

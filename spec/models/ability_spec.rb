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
    actions = %i[setup import edit update destroy]
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

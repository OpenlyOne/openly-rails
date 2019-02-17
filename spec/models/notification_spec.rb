# frozen_string_literal: true

require 'models/shared_examples/acting_as_hash_id.rb'
require 'models/shared_examples/having_jobs.rb'
require 'support/helpers/notifications_helper.rb'

RSpec.describe Notification, type: :model do
  include NotificationsHelper

  subject(:notification) { build_stubbed random_notification_factory }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  it_should_behave_like 'acting as hash ID' do
    let(:minimum_length) { 8 }
  end

  it_should_behave_like 'having jobs' do
    let(:owning_object) { notification }
  end

  describe 'aliases' do
    it do
      expect(notification.method(:to_partial_path))
        .to eq notification.method(:partial_name)
    end
    it do
      expect(notification.method(:subject_line))
        .to eq notification.method(:title)
    end
    it do
      expect(notification.method(:unread?).original_name)
        .to eq notification.method(:unopened?).original_name
    end
    it do
      expect(notification.method(:notifying_object).original_name)
        .to eq notification.method(:notifiable).original_name
    end
  end

  describe '.notification_helper_for(notifying_object, options = {})' do
    subject(:helper) do
      Notification.notification_helper_for(
        object, source: 'y', key: 'revision.create'
      )
    end
    let(:object) { instance_double VCS::Commit }

    before do
      allow(object).to receive(:model_name).and_return 'VCS::Commit'
      allow(Notifications::VCS::Commits::Create)
        .to receive(:new).with(object, source: 'y').and_return 'instance'
    end

    it 'returns an instance of notification helper' do
      is_expected.to eq 'instance'
    end

    context 'when key is not passed' do
      subject(:helper) do
        Notification.notification_helper_for(object, source: 'y')
      end

      it { expect { helper }.to raise_error KeyError }
    end
  end

  describe '#partial_name' do
    subject { notification.partial_name }
    let(:notification_helper) do
      instance_double Notifications::VCS::Commits::Create
    end
    let(:active_model_name) { instance_double ActiveModel::Name }

    before do
      allow(notification)
        .to receive(:notification_helper)
        .and_return notification_helper
      allow(notification_helper)
        .to receive_message_chain(:class, :to_s)
        .and_return('Notifications::Parents::Classes::Action')
    end

    it { is_expected.to eq 'parents/classes/action_notification' }
  end

  describe '#title' do
    subject               { notification.title }
    let(:revision_helper) do
      instance_double Notifications::VCS::Commits::Create
    end

    before do
      allow(notification)
        .to receive(:notification_helper)
        .and_return revision_helper
      allow(revision_helper)
        .to receive(:title).and_return 'title'
    end

    it { is_expected.to eq 'title' }
  end
end

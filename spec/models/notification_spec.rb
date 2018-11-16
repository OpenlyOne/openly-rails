# frozen_string_literal: true

require 'models/shared_examples/acting_as_hash_id.rb'
require 'models/shared_examples/having_jobs.rb'

RSpec.describe Notification, type: :model do
  subject(:notification) { build_stubbed :notification }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  it_should_behave_like 'acting as hash ID'

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
    subject       { Notification.notification_helper_for(object, source: 'y') }
    let(:object)  { instance_double VCS::Commit }

    before do
      allow(object).to receive(:model_name).and_return 'VCS::Commit'
      allow(Notifications::VCS::Commit)
        .to receive(:new).with(object, source: 'y').and_return 'instance'
    end

    it 'returns an instance of notification helper' do
      is_expected.to eq 'instance'
    end
  end

  describe '#partial_name' do
    subject                 { notification.partial_name }
    let(:notifying_object)  { instance_double VCS::Commit }
    let(:active_model_name) { instance_double ActiveModel::Name }

    before do
      allow(notification)
        .to receive(:notifying_object)
        .and_return notifying_object
      allow(notifying_object)
        .to receive(:model_name)
        .and_return active_model_name
      allow(active_model_name)
        .to receive(:param_key).and_return 'object_model_name'
    end

    it { is_expected.to eq 'object_model_name_notification' }
  end

  describe '#title' do
    subject               { notification.title }
    let(:revision_helper) { instance_double Notifications::VCS::Commit }

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

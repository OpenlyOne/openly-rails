# frozen_string_literal: true

require 'support/helpers/notifications_helper.rb'

RSpec.describe 'notifications/index', type: :view do
  include NotificationsHelper

  let(:notifications) do
    notification_factories.map do |factory|
      create(factory)
    end
  end
  let(:unopened) { false }

  before do
    assign(:notifications, notifications)
  end

  before do
    notifications.each do |notification|
      allow(notification).to receive(:unread?).and_return unopened
    end
  end

  it 'renders a link to each notification' do
    render
    notifications.each do |notification|
      expect(rendered).to have_link '', href: notification_path(notification)
    end
  end

  it 'renders the notification title' do
    render
    notifications.each do |notification|
      expect(rendered).to have_text notification.title
    end
  end

  it "does not render a 'new' badge" do
    render
    expect(rendered).not_to have_text 'new'
  end

  context 'when no notifications exist' do
    let(:notifications) { [] }

    it 'renders that there are no notifications' do
      render
      expect(rendered).to have_text 'You do not have any notifications.'
    end
  end

  context 'when notification is unopened' do
    let(:unopened) { true }

    it "renders a 'new' badge" do
      render
      expect(rendered).to have_text 'new'
    end
  end
end

# frozen_string_literal: true

RSpec.describe 'notifications/index', type: :view do
  let(:notifications) { build_stubbed_list :notification, 3 }
  let(:unopened)      { false }

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

  it 'renders the notification message' do
    render
    notifications.each do |notification|
      notifier = notification.notifier
      project = notification.notifiable.project
      expect(rendered).to have_text(
        "#{notifier.name} created a revision in #{project.title}"
      )
    end
  end

  it 'renders the title of the revision' do
    render
    notifications.each do |notification|
      expect(rendered).to have_text notification.notifiable.title
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

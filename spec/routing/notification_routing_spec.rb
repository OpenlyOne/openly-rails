# frozen_string_literal: true

RSpec.describe 'routes for notifications', type: :routing do
  it 'has an index route' do
    expect(notifications_path).to eq '/notifications'
    expect(get: '/notifications').to route_to('notifications#index')
  end

  it 'has show route' do
    expect(notification_path('id')).to eq '/notifications/id'
    expect(get: '/notifications/id').to route_to('notifications#show', id: 'id')
  end
end

# frozen_string_literal: true

RSpec.describe 'routes for profiles', type: :routing do
  it 'has a show route' do
    expect(profile_path('handle')).to eq '/handle'
    expect(get: '/some_handle').to(
      route_to('profiles#show', handle: 'some_handle')
    )
  end
end

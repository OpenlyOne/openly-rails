# frozen_string_literal: true

RSpec.describe 'routes for profiles', type: :routing do
  it 'has a show route' do
    expect(profile_path('handle')).to eq '/handle'
    expect(get: '/some_handle').to(
      route_to('profiles#show', handle: 'some_handle')
    )
  end

  it 'has an edit route' do
    expect(edit_profile_path('handle')).to eq '/handle/edit'
    expect(get: '/some_handle/edit').to(
      route_to('profiles#edit', handle: 'some_handle')
    )
  end

  it 'has an update route' do
    expect(profile_path('handle')).to eq '/handle'
    expect(patch: '/handle').to route_to 'profiles#update', handle: 'handle'
    expect(put: '/handle').to route_to 'profiles#update', handle: 'handle'
  end
end

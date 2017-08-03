# frozen_string_literal: true

RSpec.describe 'devise/registrations/edit', type: :view do
  before do
    without_partial_double_verification do
      allow(view).to receive(:resource).and_return build_stubbed(:account)
      allow(view).to receive(:resource_name).and_return :account
      allow(view).to(
        receive(:devise_mapping).and_return(Devise.mappings[:account])
      )
    end
  end

  it 'marks email input as readonly' do
    render
    expect(rendered).to have_css('input#account_email[readonly=readonly]')
  end

  it 'tells the user that email cannot be changed' do
    render
    expect(rendered).to have_css('label', text: 'Email (cannot be changed)')
  end
end

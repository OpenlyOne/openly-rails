# frozen_string_literal: true

RSpec.describe 'projects/access_unauthorized', type: :view do
  let(:account_signed_in) { true }

  before do
    allow(view).to receive(:account_signed_in?).and_return account_signed_in
  end

  it 'tells the user that they are not authorized to access the project' do
    render
    expect(rendered).to have_text 'not authorized to access'
  end

  it 'tells the user to ask owner to be added as a collaborator' do
    render
    expect(rendered)
      .to have_text 'Ask the owner to add you as a project collaborator.'
  end

  context 'when user is not logged in' do
    let(:account_signed_in) { false }

    it 'has a link to log in' do
      render
      expect(rendered).to have_link href: new_session_path, text: 'Log in'
    end
  end
end

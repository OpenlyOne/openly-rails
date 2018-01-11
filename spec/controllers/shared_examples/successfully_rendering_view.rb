# frozen_string_literal: true

# Expect request to be run successfully, including rendering of view
# This test can be used to verify that instance variables are correctly set when
# the alternative path in a controller action is taken (e.g. render 'new' in
# the create action)
RSpec.shared_examples 'successfully rendering view' do
  render_views

  it { expect(response).to have_http_status :success }

  it 'successfully renders view' do
    expect { run_request }.not_to raise_error
  end
end

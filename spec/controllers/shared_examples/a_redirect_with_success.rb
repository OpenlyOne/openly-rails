# frozen_string_literal: true

# Expect the controller action to redirect and set flash message
RSpec.shared_examples 'a redirect with success' do
  let(:resource_name) { @controller.controller_path.singularize.humanize }
  let(:inflected_action_name) do
    case request.params[:action].to_s
    when 'create'
      'created'
    when 'update'
      'updated'
    when 'destroy'
      'deleted'
    end
  end
  before { run_request }

  it 'redirects to resource' do
    expect(response).to redirect_to redirect_location
  end

  it 'sets flash message' do
    expect(@controller).to set_flash[:notice].to(
      "#{resource_name} successfully #{inflected_action_name}."
    )
  end
end

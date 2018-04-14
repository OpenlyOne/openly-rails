# frozen_string_literal: true

# Controller for resources
class ResourcesController < ApplicationController
  # GET /resources/:id
  def show
    @resource = Resource.find(params[:id])
    redirect_to @resource.link
  end
end

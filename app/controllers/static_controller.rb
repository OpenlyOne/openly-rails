# frozen_string_literal: true

# Controller for all static pages: index, about, contact, etc...
class StaticController < ApplicationController
  layout 'landing'

  def github_for_documents
    @title = 'Manage Documents Just Like Code'
    render 'static/github_for_documents/index'
  end

  def open_collaboration
    @title = 'Network of Open Initiatives'
    render 'static/open_collaboration/index'
  end
end

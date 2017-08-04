# frozen_string_literal: true

# Handles 404, 422, and 500 errors
class ErrorsController < ApplicationController
  def not_found
    render status: 404
  end

  def unacceptable
    render status: 422
  end

  def internal_server_error
    render status: 500
  end
end

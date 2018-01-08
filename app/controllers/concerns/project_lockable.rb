# frozen_string_literal: true

# Support project/repository locking of controller actions and delpaying
# render and redirects until after lock has completed
module ProjectLockable
  extend ActiveSupport::Concern

  # Intercept calls to #performed?
  # #performed? is used to check if render/redirect has already been performed
  def performed?
    return super unless @delay_render_and_redirect
    @render_called || @redirect_called
  end

  private

  # Intercept calls to #render and save arguments for later
  def render(*args)
    return super unless @delay_render_and_redirect

    @render_called = true
    @render_arguments = args
  end

  # Intercept calls to #redirect_to and save arguments for later
  def redirect_to(*args)
    return super unless @delay_render_and_redirect

    @redirect_called = true
    @redirect_arguments = args
  end

  # Wrap controller action in project repository lock
  # Usage:
  #   around_action :wrap_action_in_project_lock
  def wrap_action_in_project_lock
    @delay_render_and_redirect = true

    @project.repository.lock do
      start_time = Time.zone.now
      yield
      time_passed = (Time.zone.now - start_time).in_milliseconds.round(1)
      logger.info "Repository lock finished in #{time_passed}ms"
    end

    @delay_render_and_redirect = false

    # execute delayed render or redirect
    return redirect_to(*@redirect_arguments) if @redirect_called
    return render(*@render_arguments) if @render_called
  end
end

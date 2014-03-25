class Users::InvitationsController < Devise::InvitationsController
  before_filter :configure_permitted_parameters
  layout "sessions"

  def new
    self.resource = resource_class.new
    render layout: "application"
  end

  # POST /resource/invitation
  def create
    self.resource = invite_resource

    if resource.errors.empty?
      yield resource if block_given?
      set_flash_message :notice, :send_instructions, :email => self.resource.email if self.resource.invitation_sent_at
      respond_with resource, :location => after_invite_path_for(resource)
    else
      respond_with_navigational(resource) { render layout: "application", :action => "new" }
    end
  end

  protected
  def after_invite_path_for(resource)
    new_user_invitation_path
  end

  def after_accept_path_for(resource)
    resource.push_follower(resource.invited_by_id)
    UserMailer.delay.welcome(resource.id)
    edit_user_registration_path
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:accept_invitation) do |u| 
      u.permit(:login, :email, :password, :password_confirmation, :invitation_token)
    end
  end
end

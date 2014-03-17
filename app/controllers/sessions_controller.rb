class SessionsController < Devise::SessionsController
  def new
    super
    session["user_return_to"] = request.referrer
  end

  def create
    resource = warden.authenticate!(:scope => resource_name, :recall => "#{controller_path}#new")
    #set_flash_message(:success, :signed_in) if is_navigational_format?
    sign_in(resource_name, resource)
    resource.ensure_private_token!
    respond_to do |format|
      format.html { redirect_to after_sign_in_path_for(resource) }
      format.json { render :status => '201', :json => resource.as_json(:only => [:login, :email, :private_token]) }
    end
  end

  # DELETE /resource/sign_out
  def destroy
    redirect_path = after_sign_out_path_for(resource_name)
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    #set_flash_message :notice, :signed_out if signed_out && is_navigational_format?

    # We actually need to hardcode this as Rails default responder doesn't
    # support returning empty response on GET request
    respond_to do |format|
      format.all { head :no_content }
      format.any(*navigational_formats) { redirect_to redirect_path }
    end
  end

  def after_sign_in_path_for(user)
    user_url(user.login)
  end


end

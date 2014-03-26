# coding: utf-8
class AccountController < Devise::RegistrationsController
  protect_from_forgery
  before_filter :check_allow_register
  layout "application"
  def edit
    @user = current_user
    # 首次生成用户 Token
    @user.update_private_token if @user.private_token.blank?
    drop_breadcrumb "账户设置"
  end

  def update
    super
  end
# GET /resource/sign_up
  def new
    build_resource({})
    render layout: "account"
  end
  # POST /resource
  def create
    build_resource(sign_up_params)
    resource.login = params[resource_name][:login]
    resource.email = params[resource_name][:email]
    if resource.save
      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_navigational_format?
        sign_in(resource_name, resource)
        respond_with resource, :location => after_sign_up_path_for(resource)
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_navigational_format?
        expire_session_data_after_sign_in!
        respond_with resource, :location => after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      render layout: "account", :action => "new"
    end
  end

  def destroy
    resource.soft_delete
    sign_out_and_redirect("/login")
    set_flash_message :notice, :destroyed
  end
  protected
  def check_allow_register
    if SiteConfig.allow_register != "true"
      redirect_to(new_user_session_url)
    end
  end
end

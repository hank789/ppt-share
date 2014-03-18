# coding: utf-8
class HomeController < ApplicationController
  def index
    if current_user.present?
      redirect_to(user_url(current_user.login));
    else
      redirect_to(new_user_session_url);
    end
  end

  def api
    drop_breadcrumb("API", root_path)
  end

end

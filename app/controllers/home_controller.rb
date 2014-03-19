# coding: utf-8
class HomeController < ApplicationController
  def index
    if current_user.present?
      drop_breadcrumb("首页", root_path)
      set_seo_meta("#{t("menu.slogan")}")
    else
      redirect_to(new_user_session_url)
    end
  end

  def api
    drop_breadcrumb("API", root_path)
  end

end

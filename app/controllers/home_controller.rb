# coding: utf-8
class HomeController < ApplicationController
  def index
    if current_user.present?
      redirect_to(user_url(current_user.login));
    end

    drop_breadcrumb("首页", root_path)
    set_seo_meta("#{t("menu.slogan")}")
    @slides = Slide.excellent.recent.fields_for_list.includes(:user).limit(8)
    @slides_col_md=3
  end

  def api
    drop_breadcrumb("API", root_path)
  end

end

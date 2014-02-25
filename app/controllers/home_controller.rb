# coding: utf-8
class HomeController < ApplicationController
  def index
    drop_breadcrumb("首页", root_path)
    set_seo_meta("#{t("menu.slogan")}")
    @slides = Slide.high_likes.last_week_created.fields_for_list.includes(:user).paginate(:page => params[:page], :per_page => 8)
    @slides_col_md=3;
  end

  def api
    drop_breadcrumb("API", root_path)
  end

end

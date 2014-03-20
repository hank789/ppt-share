# coding: utf-8
class HomeController < ApplicationController
  def index
    if current_user.present?
      @activities_followed = PublicActivity::Activity.desc(:created_at).where(:key.ne => "reply.mention").where(:owner_id.in => current_user.follower_ids).paginate(:page => params[:page], :per_page => 20)
      @activities_with_me = PublicActivity::Activity.desc(:created_at).where(:recipient_id => current_user.id).paginate(:page => params[:page], :per_page => 20)
      @activities_important = PublicActivity::Activity.desc(:created_at).where(:owner_id.in => current_user.follower_ids).where(:trackable_type => "Slide").paginate(:page => params[:page], :per_page => 20)
      @slides_suggest = Slide.excellent.recent.fields_for_list.where(:user_id.ne => current_user.id).limit(6)
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

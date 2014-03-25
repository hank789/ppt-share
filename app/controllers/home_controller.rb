# coding: utf-8
class HomeController < ApplicationController
  before_filter :count_activity, :only => [:index, :releated_a, :follow_a]
  def index
    @activities = PublicActivity::Activity.desc(:created_at).where(:owner_id.in => current_user.follower_ids).where(:trackable_type => "Slide").paginate(:page => params[:page], :per_page => 20)
  end

  def releated_a
    @activities = PublicActivity::Activity.desc(:created_at).where(:recipient_id => current_user.id).paginate(:page => params[:page], :per_page => 20)
    render :action => "index"
  end

  def follow_a
    @activities = PublicActivity::Activity.desc(:created_at).where(:key.ne => "reply.mention").where(:owner_id.in => current_user.follower_ids).paginate(:page => params[:page], :per_page => 20)
    render :action => "index"
  end
  # 发现
  def explore
    drop_breadcrumb("发现")
  end

  def api
    drop_breadcrumb("API", root_path)
  end
  protected
  def count_activity
    if current_user.present?
      # @activities_followed_count = PublicActivity::Activity.where(:key.ne => "reply.mention").where(:owner_id.in => current_user.follower_ids).count
      # @activities_with_me_count = PublicActivity::Activity.where(:recipient_id => current_user.id).count
      # @activities_important_count = PublicActivity::Activity.where(:owner_id.in => current_user.follower_ids).where(:trackable_type => "Slide").count

      @slides_suggest = Slide.excellent.recent.fields_for_list.where(:user_id.ne => current_user.id).limit(6)
      drop_breadcrumb("首页", root_path)
      set_seo_meta("#{t("menu.slogan")}")
    else
      redirect_to(new_user_session_url)
    end
  end

end

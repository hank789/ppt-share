# coding: utf-8
class UsersController < ApplicationController
  before_filter :require_user, :only => [:auth_unbind, :home, :show, :slides, :collections, :slides_popular, :favorite_slides]
  before_filter :set_menu_active
  before_filter :find_user, :only => [:show, :slides, :likes, :collections, :slides_popular, :favorite_slides]
  caches_action :index, :expires_in => 2.hours, :layout => false

  def index
    @total_user_count = User.count
    @active_users = User.hot.limit(100)
    drop_breadcrumb t("common.index")
  end

  def show
    @slides = @user.slides.recent_update.paginate(:page => params[:page], :per_page => 20)
    #关注
    @following = User.find(@user.follower_ids)
    #粉丝
    @followers = User.find(@user.followed_ids)
    drop_breadcrumb(@user.login, user_path(@user.login))

  end

  def favorite_slides
    @slides = @user.slides.recent_update.where(:_id.in => @user.favorite_slide_ids).paginate(:page => params[:page], :per_page => 20)
    #关注
    @following = User.find(@user.follower_ids)
    #粉丝
    @followers = User.find(@user.followed_ids)
    drop_breadcrumb(@user.login, user_path(@user.login))
    render :action => "show"
  end

  def slides
    @slides = @user.slides.recent_update.fields_for_list.paginate(:page => params[:page], :per_page => 20)
    @slides_count = @user.slides.count
    @slides_popular_count = @user.slides.where(:replies_count.gt => 5).count
    @slides_suggest = Slide.excellent.recent_update.fields_for_list.where(:user_id.ne => current_user.id).limit(6)
    drop_breadcrumb(@user.login, user_path(@user.login))
    drop_breadcrumb("幻灯片")
  end

  def slides_popular
    @slides = @user.slides.high_replies.where(:replies_count.gt => 5).fields_for_list.paginate(:page => params[:page], :per_page => 20)
    @slides_count = @user.slides.count
    @slides_popular_count = @user.slides.where(:replies_count.gt => 5).count
    @slides_suggest = Slide.excellent.recent_update.fields_for_list.where(:user_id.ne => current_user.id).limit(6)
    drop_breadcrumb(@user.login, user_path(@user.login))
    drop_breadcrumb("幻灯片")
    render :action => "slides"
  end


  def likes
    @slides = Slide.where(:_id.in => @user.like_slide_ids).paginate(:page => params[:page], :per_page => 20)
    drop_breadcrumb(@user.login, user_path(@user.login))
    drop_breadcrumb(t("users.menu.likes"))
  end

  def collections
    @slides = Slide.recent_update.where(:_id.in => @user.favorite_slide_ids).paginate(:page => params[:page], :per_page => 20)
    drop_breadcrumb(@user.login, user_path(@user.login))
    drop_breadcrumb(t("users.menu.collections"))
  end

  def auth_unbind
    provider = params[:provider]
    if current_user.authorizations.count <= 1
      redirect_to edit_user_registration_path, :flash => {:error => t("users.unbind_warning")}
      return
    end

    current_user.authorizations.destroy_all({:provider => provider})
    redirect_to edit_user_registration_path, :flash => {:warring => t("users.unbind_success", :provider => provider.titleize)}
  end

  def update_private_token
    current_user.update_private_token
    render :text => current_user.private_token
  end

  def city
    @location = Location.find_by_name(params[:id])
    if @location.blank?
      render_404
      return
    end

    @users = User.where(:location_id => @location.id).desc('replies_count').paginate(:page => params[:page], :per_page => 30)

    if @users.count == 0
      render_404
      return
    end

    drop_breadcrumb(@location.name)
  end

  def follow
    @user = User.find(current_user.id)
    @user.push_follower(params[:id])
    render :text => "1"
  end

  def unfollow
    @user = User.find(current_user.id)
    @user.pull_follower(params[:id])
    render :text => "1"
  end

  # 我关注的
  def following
    @users = User.find(current_user.follower_ids)
  end
  # 我被人关注
  def followers
    @users = User.find(current_user.followed_ids)
  end
  protected
  def find_user
    # 处理 login 有大写字母的情况
    if params[:id] != params[:id].downcase
      redirect_to request.path.downcase, :status => 301
      return
    end

    @user = User.where(:login => /^#{params[:id]}$/i).first
    render_404 if @user.nil?
  end

  def set_menu_active
    @current = @current = ['/users']
  end

end

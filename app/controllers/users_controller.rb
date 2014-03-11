# coding: utf-8
class UsersController < ApplicationController
  before_filter :require_user, :only => [:auth_unbind, :home, :show, :slides, :collections]
  before_filter :set_menu_active
  before_filter :find_user, :only => [:show, :slides, :likes, :collections, :workspace, :home]
  caches_action :index, :expires_in => 2.hours, :layout => false

  def index
    @total_user_count = User.count
    @active_users = User.hot.limit(100)
    drop_breadcrumb t("common.index")
  end

  def home
    @activities = PublicActivity::Activity.desc(:created_at).where(:owner_type => "User").any_in(:owner_id => current_user.follower_ids).paginate(:page => params[:page], :per_page => 20)
    @current_slides = @user.slides.recent_update.limit(20)
  end

  def show
    redirect_to("/#{@user.login}/slides")
  end

  def slides
    @slides = @user.slides.recent.paginate(:page => params[:page], :per_page => 30)
    drop_breadcrumb(@user.login, user_path(@user.login))
    drop_breadcrumb(t("slides.title"))
  end

  def workspace
    @orphan_slides = @user.slides.recent
    drop_breadcrumb(@user.login, user_path(@user.login))
  end


  def likes
    @slides = Slide.where(:_id.in => @user.like_slide_ids).paginate(:page => params[:page], :per_page => 30)
    drop_breadcrumb(@user.login, user_path(@user.login))
    drop_breadcrumb(t("users.menu.likes"))
  end

  def collections
    @slides = Slide.where(:_id.in => @user.favorite_slide_ids).paginate(:page => params[:page], :per_page => 30)
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

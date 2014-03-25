# coding: utf-8
class SlidesController < ApplicationController

  load_and_authorize_resource :only => [:new, :edit, :create, :update, :destroy, :favorite, :suggest, :unsuggest]

  before_filter :set_menu_active
  before_filter :init_base_breadcrumb

  def index
    @slides = Slide.last_actived.includes(:user).paginate(:page => params[:page], :per_page => 15)
    set_seo_meta("#{t("menu.slides")}", "#{Setting.app_name}#{t("menu.slides")}")
    drop_breadcrumb(t("slides.slide_list.hot_slide"))
  end


  %w(no_reply popular).each do |name|
    define_method(name) do
      @slides = Slide.send(name.to_sym).includes(:user).paginate(:page => params[:page], :per_page => 15)
      drop_breadcrumb(t("slides.slide_list.#{name}"))
      set_seo_meta([t("slides.slide_list.#{name}"), t("menu.slides")].join(" &raquo; "))
      render :action => "index"
    end
  end

  def recent
    @slides = Slide.recent.fields_for_list.includes(:user).paginate(:page => params[:page], :per_page => 15, :total_entries => 1500)
    drop_breadcrumb(t("slides.slide_list.recent"))
    set_seo_meta([t("slides.slide_list.recent"), t("menu.slides")].join(" &raquo; "))
    render :action => "index"
  end

  def excellent
    @slides = Slide.excellent.recent.fields_for_list.includes(:user).paginate(page: params[:page], per_page: 15, total_entries: 500)
    drop_breadcrumb(t("slides.slide_list.excellent"))
    set_seo_meta([t("slides.slide_list.excellent"), t("menu.slides")].join(" &raquo; "))
    render :action => "index"
  end

  def download
    unless current_user
      redirect_to new_user_session_path
    else
      attach = Attach.find(params[:id])
      slide = Slide.find(attach.slide_id)
      key = attach.file.to_s.split("#{Setting.qiniu_bucket_domain}/")
      if key.length == 2
        stat = Qiniu::RS.stat(Setting.qiniu_bucket, key[1])
        slide.downloads.incr(1)
        dlToken = Qiniu::RS.generate_download_token :expires_in => 3600, :pattern => attach.file
        file_name = attach.original_filename
        #render :text => "#{attach.file}?token=#{dlToken}"
        # data = open("#{attach.file}?token=#{dlToken}")
        send_data "#{attach.file}?token=#{dlToken}", :filename => file_name, :type => stat["mimeType"], :disposition => 'attachment', :stream => 'true', :buffer_size => '4096'
      end
    end
  end

  def show
    @slide = Slide.without_body.find(params[:id])
    @slide.hits.incr(1)
    @attach = Attach.find_by_id(@slide.attach_id)
    @show_raw = params[:raw] == "1"

    @per_page = Reply.per_page

    # 默认最后一页
    params[:page] = @slide.last_page_with_per_page(@per_page) if params[:page].blank?
    @page = params[:page].to_i > 0 ? params[:page].to_i : 1

    @replies = @slide.replies.unscoped.without_body.asc(:_id).paginate(:page => params[:page], :per_page => @per_page)
    @user = @slide.user
    # TODO
    if current_user
      # 找出用户 like 过的 Reply，给 JS 处理 like 功能的状态
      @user_liked_reply_ids = []
      @replies.each { |r| @user_liked_reply_ids << r.id if r.liked_user_ids.include?(current_user.id) }
      # 通知处理
      current_user.read_slide(@slide)
      # 是否关注过
      @has_followed = @slide.follower_ids.include?(current_user.id)
      # 是否收藏
      @has_favorited = current_user.favorite_slide_ids.include?(@slide.id)
    else
      render layout: "unauthenticated"
    end
    set_seo_meta("#{@slide.title} &raquo; #{t("menu.slides")}")
    drop_breadcrumb @slide.title
    fresh_when(:etag => [@slide, @has_favorited, @replies, @show_raw])
  end

  def attachs
    @slide = Slide.without_body.find(params[:id])
    set_seo_meta("#{@slide.title} &raquo; #{t("menu.slides")}")
    drop_breadcrumb t("slides.read_slide")
  end

  def new
    @slide = Slide.new
    @slide.tags= ""
    @slide_tags = ActsAsTaggable::Tag.all.distinct(:name).to_s

    drop_breadcrumb t("slides.new_slide")
    set_seo_meta("#{t("slides.new_slide")} &raquo; #{t("menu.slides")}")
  end

  def edit
    @slide = Slide.find(params[:id])
    @slide_tags = ActsAsTaggable::Tag.all.distinct(:name).to_s
    drop_breadcrumb t("slides.edit_slide")
    set_seo_meta("#{t("slides.edit_slide")} &raquo; #{t("menu.slides")}")
  end

  def create
    @slide = Slide.new(slide_params)
    @slide.attach_id = "" unless !@slide.attach_id.nil? && Attach.exists({:user_id => current_user.id, :_id => @slide.attach_id})
    @slide.user_id = current_user.id
    if @slide.save
      if !@slide.attach_id.blank?
        @attach = Attach.find(@slide.attach_id)
        if @attach.slide_id.nil?
          @attach.slide_id = @slide._id
          @attach.save
        end
        @slide.create_activity :create, owner: current_user, recipient: current_user
        # tag
        current_user.tag @slide, params[:slideTags].to_s.split(",")
      end
      redirect_to(slide_path(@slide.id), :notice => t("slides.create_slide_success"))
    else
      @attach_id = slide_params[:slide]
      render :action => "new"
    end
  end


  def update
    @slide = Slide.find(params[:id])
    @slide.title = slide_params[:title]
    @slide.body = slide_params[:body]
    if @slide.save
      @slide.create_activity :update, owner: current_user, recipient: current_user
      # tag
      current_user.tag @slide, params[:slideTags].to_s.split(",")
      redirect_to(slide_path(@slide.id), :notice => t("slides.update_slide_success"))
    else
      render :action => "edit"
    end
  end

  def destroy
    @slide = Slide.find(params[:id])
    @slide.destroy_by(current_user)
    redirect_to(slides_path, :notice => t("slides.delete_slide_success"))
  end

  def favorite
    if params[:type] == "unfavorite"
      current_user.unfavorite_slide(params[:id])
    else
      current_user.favorite_slide(params[:id])
    end
    render :text => "1"
  end

  def suggest
    @slide = Slide.find(params[:id])
    @slide.update_attributes(excellent: 1)
    @slide.create_activity :suggest, owner: current_user, recipient: @slide.user
    redirect_to @slide, success: "加精成功。"
  end

  def unsuggest
    @slide = Slide.find(params[:id])
    @slide.update_attribute(:excellent, 0)
    @slide.create_activity :unsuggest, owner: current_user, recipient: @slide.user
    redirect_to @slide, success: "加精已经取消。"
  end

  protected

  def set_menu_active
    @current = @current = ['/slides']
  end

  def init_base_breadcrumb
    drop_breadcrumb(t("menu.slides"), slides_path)
  end

  private

  def slide_params
    params.require(:slide).permit(:title, :body, :attach_id, :private)
  end
end

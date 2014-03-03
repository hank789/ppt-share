# coding: utf-8
class SlidesController < ApplicationController

  load_and_authorize_resource :only => [:new,:edit,:create,:update,:destroy,:favorite, :follow, :unfollow, :suggest, :unsuggest]

  before_filter :set_menu_active
  caches_action :feed, :node_feed, :expires_in => 1.hours
  before_filter :init_base_breadcrumb

  def index
    @slides = Slide.includes(:user).paginate(:page => params[:page], :per_page => 15)
    set_seo_meta("#{t("menu.slides")}","#{Setting.app_name}#{t("menu.slides")}")
    drop_breadcrumb(t("slides.slide_list.hot_slide"))
  end

  def feed
    @slides = Slide.recent.without_body.limit(20).includes(:node,:user, :last_reply_user)
    render :layout => false
  end

  def node
    @node = Node.find(params[:id])
    @slides = @node.slides.last_actived.fields_for_list.includes(:user).paginate(:page => params[:page],:per_page => 15)
    set_seo_meta("#{@node.name} &raquo; #{t("menu.slides")}","#{Setting.app_name}#{t("menu.slides")}#{@node.name}",@node.summary)
    drop_breadcrumb("#{@node.name}")
    render :action => "index"
  end

  def node_feed
    @node = Node.find(params[:id])
    @slides = @node.slides.recent.without_body.limit(20)
    render :layout => false
  end

  %w(no_reply popular).each do |name|
    define_method(name) do
      @slides = Slide.send(name.to_sym).last_actived.fields_for_list.includes(:user).paginate(:page => params[:page], :per_page => 15)
      drop_breadcrumb(t("slides.slide_list.#{name}"))
      set_seo_meta([t("slides.slide_list.#{name}"),t("menu.slides")].join(" &raquo; "))
      render :action => "index"
    end
  end

  def recent
    @slides = Slide.recent.fields_for_list.includes(:user).paginate(:page => params[:page], :per_page => 15, :total_entries => 1500)
    drop_breadcrumb(t("slides.slide_list.recent"))
    set_seo_meta([t("slides.slide_list.recent"),t("menu.slides")].join(" &raquo; "))
    render :action => "index"
  end

  def excellent
    @slides = Slide.excellent.recent.fields_for_list.includes(:user).paginate(page: params[:page], per_page: 15, total_entries: 500)
    drop_breadcrumb(t("slides.slide_list.excellent"))
    set_seo_meta([t("slides.slide_list.excellent"),t("menu.slides")].join(" &raquo; "))
    render :action => "index"
  end

	def download
		@slide = Slide.find(params[:id])
		@slide.downloads.incr(1)
		send_file @slide.slide 
		render :action => "index"
	end

  def show
    @slide = Slide.without_body.find(params[:id])
    @slide.hits.incr(1)
    #@node = @slide.node
    @show_raw = params[:raw] == "1"

    @per_page = Reply.per_page
		@in_attach = Attach.find(@slide.slide)
    # 默认最后一页
    params[:page] = @slide.last_page_with_per_page(@in_attach.replies_count, @per_page) if params[:page].blank?
    @page = params[:page].to_i > 0 ? params[:page].to_i : 1

    @replies = @in_attach.replies.unscoped.without_body.asc(:_id).paginate(:page => params[:page], :per_page => @per_page)
		# TODO 
    if current_user
      # 找出用户 like 过的 Reply，给 JS 处理 like 功能的状态
      @user_liked_reply_ids = []
      @replies.each { |r| @user_liked_reply_ids << r.id if r.liked_user_ids.include?(current_user.id) }
      # 通知处理
      current_user.read_attach(@in_attach)
      # 是否关注过
      @has_followed = @slide.follower_ids.include?(current_user.id)
      # 是否收藏
      @has_favorited = current_user.favorite_slide_ids.include?(@slide.id)
    end
    set_seo_meta("#{@slide.title} &raquo; #{t("menu.slides")}")
    #drop_breadcrumb("#{@node.try(:name)}", node_slides_path(@node.try(:id)))
    drop_breadcrumb t("slides.read_slide")

    fresh_when(:etag => [@slide,@has_followed,@has_favorited,@replies,@node,@show_raw])
  end

	def attachs
		@slide = Slide.without_body.find(params[:id])
		set_seo_meta("#{@slide.title} &raquo; #{t("menu.slides")}")
    drop_breadcrumb t("slides.read_slide")
	end 

  def new
    drop_breadcrumb t("slides.new_slide")
    set_seo_meta("#{t("slides.new_slide")} &raquo; #{t("menu.slides")}")
  end

  def edit
    @slide = Slide.find(params[:id])
    drop_breadcrumb t("slides.edit_slide")
    set_seo_meta("#{t("slides.edit_slide")} &raquo; #{t("menu.slides")}")
  end

  def create
   	@slide = Slide.new(slide_params)
		@slide.slide = "" unless !@slide.slide.nil? && Attach.exists({:user_id => current_user.id, :_id => @slide.slide})
    @slide.user_id = current_user.id
		if @slide.save
			if !@slide.slide.blank?
				@attach = Attach.find(@slide.slide)
				if @attach.slide_id.nil?
					@attach.slide_id = @slide._id
					@attach.save
        end
        @slide.create_activity :create, owner: current_user
			end
     	redirect_to(slide_path(@slide.id), :notice => t("slides.create_slide_success"))
		else
			@attach_id = slide_params[:slide]
    	render :action => "new"
    end
	end

  def preview
    @body = params[:body]

    respond_to do |format|
      format.json
    end
  end

  def update
    @slide = Slide.find(params[:id])
    @slide.title = slide_params[:title]
    @slide.body = slide_params[:body]

    if @slide.save
      @slide.create_activity :update, owner: current_user
      redirect_to(slide_path(@slide.id), :notice =>  t("slides.update_slide_success"))
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

  def follow
    @slide = Slide.find(params[:id])
    @slide.push_follower(current_user.id)
    render :text => "1"
  end

  def unfollow
    @slide = Slide.find(params[:id])
    @slide.pull_follower(current_user.id)
    render :text => "1"
  end

  def suggest
    @slide = Slide.find(params[:id])
    @slide.update_attributes(excellent: 1)
    redirect_to @slide, success: "加精成功。"
  end

  def unsuggest
    @slide = Slide.find(params[:id])
    @slide.update_attribute(:excellent,0)
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

  def init_list_sidebar
    if !fragment_exist? "slide/init_list_sidebar/hot_nodes"
      @hot_nodes = Node.hots.limit(10)
    end
    set_seo_meta(t("menu.slides"))
  end

  def slide_params
    params.require(:slide).permit(:folder_id, :title, :body, :slide, :private)
  end
end

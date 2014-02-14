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
    @slides = Topic.recent.without_body.limit(20).includes(:node,:user, :last_reply_user)
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
      @slides = Topic.send(name.to_sym).last_actived.fields_for_list.includes(:user).paginate(:page => params[:page], :per_page => 15, :total_entries => 1500)
      drop_breadcrumb(t("slides.slide_list.#{name}"))
      set_seo_meta([t("slides.slide_list.#{name}"),t("menu.slides")].join(" &raquo; "))
      render :action => "index"
    end
  end

  def recent
    @slides = Topic.recent.fields_for_list.includes(:user).paginate(:page => params[:page], :per_page => 15, :total_entries => 1500)
    drop_breadcrumb(t("slides.slide_list.recent"))
    set_seo_meta([t("slides.slide_list.recent"),t("menu.slides")].join(" &raquo; "))
    render :action => "index"
  end

  def excellent
    @slides = Topic.excellent.recent.fields_for_list.includes(:user).paginate(page: params[:page], per_page: 15, total_entries: 500)
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
    #@show_raw = params[:raw] == "1"

    @per_page = Reply.per_page
    # 默认最后一页
    params[:page] = @slide.last_page_with_per_page(@per_page) if params[:page].blank?
    @page = params[:page].to_i > 0 ? params[:page].to_i : 1

    @replies = @slide.replies.unscoped.without_body.asc(:_id).paginate(:page => params[:page], :per_page => @per_page)
		# TODO 
    if current_user && false
      # 找出用户 like 过的 Reply，给 JS 处理 like 功能的状态
      @user_liked_reply_ids = []
      @replies.each { |r| @user_liked_reply_ids << r.id if r.liked_user_ids.include?(current_user.id) }
      # 通知处理
      current_user.read_slide(@slide)
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

  def new
    drop_breadcrumb t("slides.new_slide")
    set_seo_meta("#{t("slides.new_slide")} &raquo; #{t("menu.slides")}")
  end

  def edit
    @slide = Topic.find(params[:id])
    @node = @slide.node
    drop_breadcrumb("#{@node.name}", node_slides_path(@node.id))
    drop_breadcrumb t("slides.edit_slide")
    set_seo_meta("#{t("slides.edit_slide")} &raquo; #{t("menu.slides")}")
  end

  def create
	  if !params[:file].nil?	
			@attach = Attach.new
			@attach.file= params[:file]
			@attach.save
			#Attach.new({:url => @b}).save
			render :text => @attach._id 
		else
    	@slide = Slide.new(slide_params)
    	@slide.user_id = current_user.id
			if @slide.save
				@attach = Attach.find(@slide.slide)
				if @attach.slide_id.nil?
					@attach.slide_id = @slide._id
					@attach.save
				end
      	redirect_to(slide_path(@slide.id), :notice => t("slides.create_slide_success"))
    	else
      	render :action => "new"
    	end
		end
  end

  def preview
    @body = params[:body]

    respond_to do |format|
      format.json
    end
  end

  def update
    @slide = Topic.find(params[:id])
    if @slide.lock_node == false || current_user.admin?
      # 锁定接点的时候，只有管理员可以修改节点
      @slide.node_id = slide_params[:node_id]

      if current_user.admin? && @slide.node_id_changed?
        # 当管理员修改节点的时候，锁定节点
        @slide.lock_node = true
      end
    end
    @slide.title = slide_params[:title]
    @slide.body = slide_params[:body]

    if @slide.save
      redirect_to(slide_path(@slide.id), :notice =>  t("slides.update_slide_success"))
    else
      render :action => "edit"
    end
  end

  def destroy
    @slide = Topic.find(params[:id])
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
    @slide = Topic.find(params[:id])
    @slide.push_follower(current_user.id)
    render :text => "1"
  end

  def unfollow
    @slide = Topic.find(params[:id])
    @slide.pull_follower(current_user.id)
    render :text => "1"
  end

  def suggest
    @slide = Topic.find(params[:id])
    @slide.update_attributes(excellent: 1)
    redirect_to @slide, success: "加精成功。"
  end

  def unsuggest
    @slide = Topic.find(params[:id])
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

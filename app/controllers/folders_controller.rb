# coding: utf-8
class FoldersController < ApplicationController

  load_and_authorize_resource

  before_filter :init_base_breadcrumb

  def init_base_breadcrumb
    drop_breadcrumb(t("menu.folders"), folders_path)
  end

  def index
    @folders = current_user.folders.recent_updated.paginate(:page => params[:page], :per_page => 20)
    set_seo_meta t("menu.folders")
    drop_breadcrumb("列表")
  end

  def show
    @folder =  Folder.find(params[:id])
    set_seo_meta("查看 &raquo; #{t("menu.folders")}")
    drop_breadcrumb("查看")
  end

  def new
    @folder = current_user.folders.build
    set_seo_meta("新建 &raquo; #{t("menu.folders")}")
    drop_breadcrumb(t("common.create"))
  end

  def edit
    @folder = current_user.folders.find(params[:id])
    set_seo_meta("修改 &raquo; #{t("menu.folders")}")
    drop_breadcrumb("修改")
  end

  def create
    @folder = current_user.folders.new(folder_params)
    if @folder.save
			redirect_to(folders_user_path(current_user.login), :notice => t("common.create_success"))
    else
      render :action => "new"
    end
  end

  def update
    @folder = current_user.folders.find(params[:id])
    if @folder.update_attributes(folder_params)
      redirect_to(@folder, :notice => t("common.update_success"))
    else
      render :action => "edit"
    end
  end

  def preview
    render :text => MarkdownConverter.convert( params[:body] )
  end

  def destroy
    @folder = current_user.folders.find(params[:id])
    @folder.destroy

    redirect_to(folders_url)
  end
  
  private
  
  def folder_params
    params.require(:folder).permit(:name)
  end
end

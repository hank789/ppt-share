class AttachsController < ApplicationController
  # load_and_authorize_resource :only => [:create, :destroy]
  before_filter :require_user
  #require 'open-uri'

  def create
    @attach = current_user.attachs.new
    @attach.file= params[:file]
    @attach.file_size= params[:filesize]
    @attach.file_type= params[:filetype]
    @attach.slide_id = params[:slide_id]
    @attach.original_filename = params[:file].original_filename
    if @attach.save
      #Attach.new({:url => @b}).save
      render :text => @attach._id
    else
      render :text => false
    end
  end

  def carousel
    render :text => 1
    @attach = Attach.find(params[:id])
    #respond_to do |format|
    format.json { render :json => {:success => true, :html => (render_to_string 'attachs/carousel.html.erb')} }
    format.html {}
    #end
    #box = render_cell :slides, :carousel, params[:id]
    #render :text => box.to_s
  end

end

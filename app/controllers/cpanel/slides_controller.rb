# coding: utf-8
class Cpanel::SlidesController < Cpanel::ApplicationController

  def index
    @slides = Slide.unscoped.desc(:_id).includes(:user).paginate :page => params[:page], :per_page => 30
    @attachs = Attach.unscoped.desc(:_id).where(:photo_count => 0).where(:slide_id.gt => 0)
  end

  def show
    @slide = Slide.unscoped.find(params[:id])

  end

  def convert_to_img
    attaches=Attach.where(:photo_count => 0).where(:slide_id.gt => 0).all
    attaches.each do |item|
      DocsplitWorker.perform_async(item.id)
    end
    redirect_to(cpanel_slides_url)
  end

  def new
    @slide = Slide.new
  end

  def edit
    @slide = Slide.unscoped.find(params[:id])
  end

  def create
    @slide = Slide.new(params[:slide].permit!)

    if @slide.save
      redirect_to(cpanel_slides_path, :notice => 'Slide was successfully created.')
    else
      render :action => "new"
    end
  end

  def update
    @slide = Slide.unscoped.find(params[:id])

    if @slide.update_attributes(params[:slide].permit!)
      redirect_to(cpanel_slides_path, :notice => 'Slide was successfully updated.')
    else
      render :action => "edit"
    end
  end

  def destroy
    @slide = Slide.unscoped.find(params[:id])
    @slide.destroy_by(current_user)

    redirect_to(cpanel_slides_path)
  end

  def undestroy
    @slide = Slide.unscoped.find(params[:id])
    @slide.update_attribute(:deleted_at, nil)
    redirect_to(cpanel_slides_path)
  end

  def suggest
    @slide = Slide.unscoped.find(params[:id])
    @slide.update_attribute(:suggested_at, Time.now)
    CacheVersion.slide_last_suggested_at = Time.now
    redirect_to(cpanel_slides_path, :notice => "Slide:#{params[:id]} suggested.")
  end

  def unsuggest
    @slide = Slide.unscoped.find(params[:id])
    @slide.update_attribute(:suggested_at, nil)
    CacheVersion.slide_last_suggested_at = Time.now
    redirect_to(cpanel_slides_path, :notice => "Slide:#{params[:id]} unsuggested.")
  end
end

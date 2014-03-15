# coding: utf-8
class SlideUploader < BaseUploader
  #cache store
  after :cache, :store_cache_id

  # Override the filename of the uploaded files:
  def filename
    if super.present?
      "#{@model.user.id}/#{cache_id}/#{original_filename.downcase}"
    end
  end

  def extension_white_list
    %w(pdf ppt pptx)
  end

  def move_to_cache
    true
  end

  def move_to_store
    true
  end

  # store cache id & async extract images
  def store_cache_id(args)
    @model.cache_id =  cache_id
  end

end

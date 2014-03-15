# coding: utf-8
class PhotoUploader < BaseUploader
  process :resize_to_limit => [680, nil]

  # Override the filename of the uploaded files:
  def filename
    if super.present?
      "#{@model.attach.user.id}/#{@model.attach.cache_id}/#{original_filename.downcase}"
    end
  end
end

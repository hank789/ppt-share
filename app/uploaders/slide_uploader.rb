# coding: utf-8
class SlideUploader < BaseUploader
	#cache store
	after :cache, :docsplit

  # Override the filename of the uploaded files:
  def filename
    if super.present?
      # current_path 是 Carrierwave 上传过程临时创建的一个文件，有时间标记，所以它将是唯一的
      # 此方法只使用 Ruby China 这类图片上传的场景
      @name ||= Digest::MD5.hexdigest(current_path)
      "#{Time.now.year}/#{@name}.#{file.extension.downcase}"
    end
  end

	def extension_white_list
    %w(jpg jpeg gif png ppt) end

	def move_to_cache
	  true
	end

  def move_to_store
		true
	end

	# Docsplit.extract_images(Rails.root.join(self.url))
	def docsplit(args)
		@model.cache_id = cache_id
		# cache_path = Rails.root.join('public', 'uploads', 'tmp', cache_id).to_s 
		# Docsplit.extract_images(path, :output => cache_path)
		
	end

end
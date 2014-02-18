class DocsplitWorker
	include Sidekiq::Worker
	sidekiq_options queue: "a"

	def perform(attach_id)
		attach = Attach.find(attach_id)
		cache_path = Rails.root.join('public', 'uploads', 'tmp', attach.cache_id).to_s
	  Dir.foreach(cache_path) do |item|
			next if item == '.' or item == '..'
			extract_path = cache_path + "/" + item
			Docsplit.extract_images(extract_path, :size => %w{1000x}, :format => :png, output: cache_path )
			#File.delete(extract_path)
		end
		Dir.foreach(cache_path) do |item|
			next if item == '.' or item == '..'
			@photo = attach.photos.new
			@photo.image = File.open(cache_path + "/" + item)
			@photo.save
			#FileUtils.rm(cache_path + "/" + item)
		end
		#Dir.rmdir(cache_path)
	end
end

# coding: utf-8
class Attach
  include Mongoid::Document
	include Mongoid::Timestamps
	include Mongoid::BaseModel

	field :cache_id
	field :file

	ACCESSABLE_ATTRS = [:file]

	mount_uploader :file, SlideUploader

	belongs_to :slide
	has_many :photos

	validates_presence_of :file

  after_create :docsplit
  def docsplit 
		#DocsplitWorker.perform_async(self.id)
		cache_path = Rails.root.join('public', 'uploads', 'tmp', self.cache_id).to_s
	  Dir.foreach(cache_path) do |item|
			next if item == '.' or item == '..'
			extract_path = cache_path + "/" + item
			Docsplit.extract_images(extract_path, :size => %w{1000x}, :format => :png, output: cache_path )
			File.delay.delete(extract_path)
		end
		Dir.foreach(cache_path) do |item|
			next if item == '.' or item == '..'
			@photo = self.photos.new
			@photo.image = File.open(cache_path + "/" + item)
			@photo.save
			FileUtils.delay.rm(cache_path + "/" + item)
		end
		Dir.delay.rmdir(cache_path)
   	# UserMailer.delay.welcome(self.id)
  end

end

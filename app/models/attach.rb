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
		DocsplitWorker.perform_async(self.id)
	end

end

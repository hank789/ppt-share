# coding: utf-8
class Attach
  include Mongoid::Document
	include Mongoid::Timestamps
	include Mongoid::BaseModel

	field :file

	mount_uploader :file, SlideUploader
	# convert image 
	field :convert_imgs, :type => Array, :default => []

	belongs_to :slide

	validates_presence_of :file

end

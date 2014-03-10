# coding: utf-8
class Photo
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::BaseModel

  field :image
  field :order_number

  belongs_to :user
  belongs_to :attach

  ACCESSABLE_ATTRS = [:image]

  # 封面图
  mount_uploader :image, PhotoUploader

end

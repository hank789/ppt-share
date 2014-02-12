# coding: utf-8
class Folder
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::BaseModel

  field :name
  field :sort, :type => Integer, :default => 0
  field :slides_count, :type => Integer, :default => 0

  has_many :slides

  validates_presence_of :name
  validates_uniqueness_of :name

  has_and_belongs_to_many :followers, :class_name => 'User', :inverse_of => :following_folders

  scope :sorted, desc(:sort)

end

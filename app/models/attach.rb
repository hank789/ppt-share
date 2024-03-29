# coding: utf-8
class Attach
  include Mongoid::Document
  include Mongoid::CounterCache
  include Mongoid::Timestamps
  include Mongoid::BaseModel

  field :cache_id
  field :file
  field :file_size
  field :file_type
  field :original_filename
  # 转化完成图片数量， 0为未完成转化，
  field :photo_count, type: Integer, default: 0

  index :cache_id => 1

  ACCESSABLE_ATTRS = [:file]

  mount_uploader :file, SlideUploader

  belongs_to :user
  counter_cache :name => :user, :inverse_of => :attaches
  belongs_to :slide
  has_many :photos

  validates_presence_of :file

  after_create :docsplit

  def docsplit
    DocsplitWorker.perform_async(self.id)
  end

end

# coding: utf-8
class Attach
  include Mongoid::Document
  include Mongoid::CounterCache
	include Mongoid::Timestamps
	include Mongoid::BaseModel

	field :cache_id
	field :file

	ACCESSABLE_ATTRS = [:file]

	mount_uploader :file, SlideUploader

	field :last_reply_id, :type => Integer
  field :replied_at , :type => DateTime
  field :replies_count, :type => Integer, :default => 0

	belongs_to :user
	counter_cache :name => :user, :inverse_of => :attaches
	belongs_to :slide
	has_many :photos
  has_many :replies, :dependent => :destroy

	validates_presence_of :file

  after_create :docsplit
  def docsplit 
		DocsplitWorker.perform_async(self.id)
	end

	def update_last_reply(reply)
    # replied_at 用于最新回复的排序，如果贴着创建时间在一个月以前，就不再往前面顶了
    #self.last_active_mark = Time.now.to_i if self.created_at > 1.month.ago
    self.replied_at = Time.now
    self.last_reply_id = reply.id 
    # self.last_reply_user_id = reply.user_id
    # self.last_reply_user_login = reply.user.try(:login) || nil
    self.save
  end

  # 所有的回复编号
  def reply_ids
    Rails.cache.fetch([self,"reply_ids"]) do
      self.replies.only(:_id).map(&:_id)
    end
  end

end

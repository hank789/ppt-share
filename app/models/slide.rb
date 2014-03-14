# coding: utf-8
require "auto-space"
class Slide
  include Mongoid::Document
  include PublicActivity::Common
  #tracked except: :update, :owner => proc {|controller, model| controller.current_user}
  include Mongoid::Timestamps
  include Mongoid::BaseModel
  include Mongoid::SoftDelete
  include Mongoid::CounterCache
  include Mongoid::Likeable
  include Mongoid::MarkdownBody
  include Redis::Objects
  include Mongoid::Mentionable
  include ActsAsTaggable::Taggable

  field :title
  field :body
  field :body_html
  field :last_reply_id, :type => Integer
  field :replied_at, :type => DateTime
  field :source
  field :message_id
  field :replies_count, :type => Integer, :default => 0
  # 回复过的人的 ids 列表
  field :follower_ids, :type => Array, :default => []
  field :suggested_at, :type => DateTime
  # 最后回复人的用户名 - cache 字段用于减少列表也的查询
  field :last_reply_user_login
  field :private, :type => Mongoid::Boolean, :default => false
  # 删除人
  field :who_deleted
  field :attach_id

  # 精华贴 0 否， 1 是
  field :excellent, type: Integer, default: 0
  # 用于排序的标记
  field :last_active_mark, :type => Integer
  # 记录收藏数和人
  field :favourite_user_ids, :type => Array, :default => []
  field :favourite_count, :type => Integer, :default => 0

  belongs_to :user, :inverse_of => :slides
  counter_cache :name => :user, :inverse_of => :slides
  belongs_to :last_reply_user, :class_name => 'User'
  belongs_to :last_reply, :class_name => 'Reply'
  has_many :replies, :dependent => :destroy

  has_many :attachs, :dependent => :destroy

  index :user_id => 1
  index :likes_count => 1
  index :favourite_count => 1
  index :last_active_mark => -1
  index :suggested_at => 1
  index :excellent => -1

  validates_presence_of :user_id, :title, :body
  validates_uniqueness_of :title, :scope => [:user_id]

  counter :hits, :default => 0
  counter :downloads, :default => 0

  delegate :login, :to => :user, :prefix => true, :allow_nil => true
  delegate :body, :to => :last_reply, :prefix => true, :allow_nil => true

  # scopes
  scope :last_actived, desc(:last_active_mark)
  # 推荐的幻灯片
  scope :suggest, -> { where(:suggested_at.ne => nil).desc(:suggested_at) }
  scope :fields_for_list, -> { without(:body, :body_html) }
  scope :high_likes, -> { desc(:likes_count, :_id) }
  scope :high_replies, -> { desc(:replies_count, :_id) }
  scope :no_reply, -> { where(:replies_count => 0) }
  scope :popular, -> { where(:likes_count.gt => 5) }
  scope :excellent, -> { where(:excellent.gte => 1) }
  scope :recent_update, desc(:updated_at)

  def self.find_by_message_id(message_id)
    where(:message_id => message_id).first
  end

  before_save :auto_space_with_title

  def auto_space_with_title
    self.title.auto_space!
  end

  before_create :init_last_active_mark_on_create

  def init_last_active_mark_on_create
    self.last_active_mark = Time.now.to_i
  end

  def push_follower(uid)
    return false if uid == self.user_id
    return false if self.follower_ids.include?(uid)
    self.push(follower_ids: uid)
  end

  def pull_follower(uid)
    return false if uid == self.user_id
    self.pull(follower_ids: uid)
  end

  def update_last_reply(reply)
    # replied_at 用于最新回复的排序，如果贴着创建时间在一个月以前，就不再往前面顶了
    self.last_active_mark = Time.now.to_i if self.created_at > 1.month.ago
    self.replied_at = Time.now
    self.last_reply_id = reply.id
    self.last_reply_user_id = reply.user_id
    self.last_reply_user_login = reply.user.try(:login) || nil
    self.save
  end

  # 删除并记录删除人
  def destroy_by(user)
    return false if user.blank?
    self.update_attribute(:who_deleted, user.login)
    self.destroy
  end

  def destroy
    super
    delete_notifiaction_mentions
  end

  def last_page_with_per_page(per_page)
    page = (self.replies_count.to_f / per_page).ceil
    page > 1 ? page : nil
  end

  # 所有的回复编号
  def reply_ids
    Rails.cache.fetch([self, "reply_ids"]) do
      self.replies.only(:_id).map(&:_id)
    end
  end

  def excellent?
    self.excellent >= 1
  end
end

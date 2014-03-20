# coding: utf-8
require "digest/md5"
class Reply
  include Mongoid::Document
  include PublicActivity::Common
  include Mongoid::Timestamps
  include Mongoid::BaseModel
  include Mongoid::CounterCache
  include Mongoid::SoftDelete
  include Mongoid::MarkdownBody
  include Mongoid::Mentionable
  include Mongoid::Likeable

  field :body
  field :body_html
  field :source
  field :message_id

  belongs_to :user, :inverse_of => :replies
  belongs_to :slide, :inverse_of => :replies, touch: true
  has_many :notifications, :class_name => 'Notification::Base', :dependent => :delete

  counter_cache :name => :user, :inverse_of => :replies
  counter_cache :name => :slide, :inverse_of => :replies

  index :user_id => 1
  index :slide_id => 1

  delegate :title, :to => :slide, :prefix => true, :allow_nil => true
  delegate :login, :to => :user, :prefix => true, :allow_nil => true

  validates_presence_of :body
  validates_uniqueness_of :body, :scope => [:slide_id, :user_id], :message => "不能重复提交。"
  validate do
    ban_words = (SiteConfig.ban_words_on_reply || "").split("\n").collect { |word| word.strip }
    if self.body.strip.downcase.in?(ban_words)
      self.errors.add(:body, "请勿回复无意义的内容，如你想收藏或赞这篇幻灯片，请用幻灯片后面的功能。")
    end
  end

  after_create :update_parent_slide

  def update_parent_slide
    slide.update_last_reply(self)
  end

  # 更新的时候也更新幻灯片的 updated_at 以便于清理缓存之类的东西
  after_update :update_parent_slide_updated_at
  # 删除的时候也要更新 Slide 的 updated_at 以便清理缓存
  after_destroy :update_parent_slide_updated_at

  def update_parent_slide_updated_at
    if not self.slide.blank?
      self.slide.touch
    end
  end


  after_create do
    Reply.delay.send_slide_reply_notification(self.id)
  end

  def self.per_page
    50
  end

  def self.send_slide_reply_notification(reply_id)
    reply = Reply.find_by_id(reply_id)
    return if reply.blank?
    slide = Slide.find_by_id(reply.slide_id)
    return if slide.blank?

    notified_user_ids = reply.mentioned_user_ids

    # 给发帖人发回帖通知
    if reply.user_id != slide.user_id && !notified_user_ids.include?(slide.user_id)
      Notification::SlideReply.create :user_id => slide.user_id, :reply_id => reply.id
      notified_user_ids << slide.user_id
    end

    # 给关注者发通知
    slide.follower_ids.each do |uid|
      # 排除同一个回复过程中已经提醒过的人
      next if notified_user_ids.include?(uid)
      # 排除回帖人
      next if uid == reply.user_id
      puts "Post Notification to: #{uid}"
      Notification::SlideReply.create :user_id => uid, :reply_id => reply.id
    end
    true
  end

  # 是否热门
  def popular?
    self.likes_count >= 5
  end

  def destroy
    super
    notifications.delete_all
    delete_notifiaction_mentions
  end
end

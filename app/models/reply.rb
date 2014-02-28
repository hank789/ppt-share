# coding: utf-8
require "digest/md5"
class Reply
  include Mongoid::Document
  include PublicActivity::Model
  tracked :owner => proc {|controller, model| controller.current_user},
          :params => {
              :summary => proc {|controller, model| model.body},
              :attach_id => proc {|controller, model| model.attach_id}
          }
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
  belongs_to :attach, :inverse_of => :replies, touch: true
  has_many :notifications, :class_name => 'Notification::Base', :dependent => :delete

  counter_cache :name => :user, :inverse_of => :replies
  counter_cache :name => :attach, :inverse_of => :replies

  index :user_id => 1
  index :attach_id => 1

  delegate :title, :to => :attach, :prefix => true, :allow_nil => true
  delegate :login, :to => :user, :prefix => true, :allow_nil => true

  validates_presence_of :body
  validates_uniqueness_of :body, :scope => [:attach_id, :user_id], :message => "不能重复提交。"
  validate do
    ban_words = (SiteConfig.ban_words_on_reply || "").split("\n").collect { |word| word.strip }
    if self.body.strip.downcase.in?(ban_words)
      self.errors.add(:body,"请勿回复无意义的内容，如你想收藏或赞这篇帖子，请用帖子后面的功能。")
    end
  end

  after_create :update_parent_attach
  def update_parent_attach
    attach.update_last_reply(self)
  end

  # 更新的时候也更新话题的 updated_at 以便于清理缓存之类的东西
  after_update :update_parent_attach_updated_at
  # 删除的时候也要更新 Attach 的 updated_at 以便清理缓存
  after_destroy :update_parent_attach_updated_at
  def update_parent_attach_updated_at
    if not self.attach.blank?
      self.attach.touch
    end
  end
  
  

  after_create do
    Reply.delay.send_attach_reply_notification(self.id)
  end

  def self.per_page
    50
  end

  def self.send_attach_reply_notification(reply_id)
    reply = Reply.find_by_id(reply_id)
    return if reply.blank?
    attach = Attach.find_by_id(reply.attach_id)
    return if attach.blank?

    notified_user_ids = reply.mentioned_user_ids

    # 给发帖人发回帖通知
    if reply.user_id != attach.user_id && !notified_user_ids.include?(attach.user_id)
      Notification::AttachReply.create :user_id => attach.user_id, :reply_id => reply.id
      notified_user_ids << attach.user_id
    end

    # 给关注者发通知
    attach.follower_ids.each do |uid|
      # 排除同一个回复过程中已经提醒过的人
      next if notified_user_ids.include?(uid)
      # 排除回帖人
      next if uid == reply.user_id
      puts "Post Notification to: #{uid}"
      Notification::AttachReply.create :user_id => uid, :reply_id => reply.id
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

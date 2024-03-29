# coding: utf-8
class Notification::SlideReply < Notification::Base
  belongs_to :reply
  delegate :body, :to => :reply, :prefix => true, :allow_nil => true

  def notify_hash
    return "" if self.reply.blank?
    {
        :title => "关注的幻灯片有了新回复:",
        :content => self.reply_body[0, 30],
        :content_path => self.content_path
    }
  end

  def content_path
    return "" if self.reply.blank?
    url_helpers.slide_path(self.reply.slide.id)
  end
end

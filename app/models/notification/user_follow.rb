# coding: utf-8
class Notification::UserFollow < Notification::Base

  field :follower_id, :type => Integer, :default => 0
  def notify_hash
    follower = User.find(self.follower_id)
    return if follower.blank?
    {
        :title => ["#{follower.login} ", "关注了你: "].join(""),
        :content => '',
        :content_path => self.content_path
    }
  end

  def content_path
    return "" if self.follower_id.blank?
    url_helpers.user_path(self.follower_id)
  end
end

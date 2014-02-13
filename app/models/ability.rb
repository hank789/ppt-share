class Ability
  include CanCan::Ability

  def initialize(user)

    if user.blank?
      # not logged in
      cannot :manage, :all
      basic_read_only

    elsif user.has_role?(:admin)
      # admin
      can :manage, :all
    elsif user.has_role?(:member)
			# Slide Folder
			if !user.newbie?
				can :create, Slide
				can :create, Folder
			end
      
      # Reply
      # 新手用户晚上禁止回帖，防 spam，可在面板设置是否打开
      if !(user.newbie? &&
           (SiteConfig.reject_newbie_reply_in_the_evening == 'true') &&
           (Time.zone.now.hour < 9 || Time.zone.now.hour > 22))
        can :create, Reply
      end
      can :update, Reply do |reply|
        reply.user_id == user.id
      end
      can :destroy, Reply do |reply|
        reply.user_id == user.id
      end

      # Photo
      can :tiny_new, Photo
      can :create, Photo
      can :update, Photo do |photo|
        photo.user_id == photo.id
      end
      can :destroy, Photo do |photo|
        photo.user_id == photo.id
      end

      # Comment
      can :create, Comment
      can :update, Comment do |comment|
        comment.user_id == comment.id
      end
      can :destroy, Comment do |comment|
        comment.user_id == comment.id
      end

      basic_read_only
    else
      # banned or unknown situation
      cannot :manage, :all
      basic_read_only
    end

  end

  protected
    def basic_read_only
      can :read,Slide

      can :read, Reply

      can :read, Photo
      can :read, Comment
    end
end

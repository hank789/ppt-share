require "digest/md5"

module MakeSlide
  module APIEntities
    class User < Grape::Entity
      expose :id, :login
      expose(:avatar_url) do |model, opts|
        if model.avatar?
          model.avatar.url(:large)
        else
          hash = Digest::MD5.hexdigest(model.email || "")
          "#{Setting.gravatar_proxy}/avatar/#{hash}.png?s=120"
        end
      end
    end

    class UserSlide < Grape::Entity
      expose :id, :title, :body, :body_html, :created_at, :updated_at, :replied_at, :replies_count, :node_name, :node_id, :last_reply_user_login
    end

    class DetailUser < Grape::Entity
      expose :id, :name, :login, :location, :company, :twitter, :website, :bio, :tagline, :github_url
      expose :email do |model, opts|
        model.email_public ? model.email : ''
      end

      # deprecated: gravatar_hash, use avatar_url for user avatar
      expose(:gravatar_hash) { |model, opts| Digest::MD5.hexdigest(model.email || "") }
      expose(:avatar_url) do |model, opts|
        if model.avatar?
          model.avatar.url(:large)
        else
          hash = Digest::MD5.hexdigest(model.email || "")
          "#{Setting.gravatar_proxy}/avatar/#{hash}.png?s=120"
        end
      end
      expose(:slides, :unless => { :collection => true }) do |model, opts|
        APIEntities::UserSlide.represent model.slides.recent.limit(opts[:slides_limit] ||= 1)
      end
    end

    class Reply < Grape::Entity
      expose :id, :body, :body_html, :created_at, :updated_at, :deleted_at, :slide_id
      expose :user, :using => APIEntities::User
    end
    
    class Slide < Grape::Entity
      expose :id, :title, :created_at, :updated_at, :replied_at, :replies_count, :node_name, :node_id, :last_reply_user_id, :last_reply_user_login
      expose :user, :using => APIEntities::User
    end

    class DetailSlide < Slide
      expose :id, :title, :created_at, :updated_at, :replied_at, :replies_count, :node_name, :node_id, :last_reply_user_id, :last_reply_user_login, :body, :body_html
      expose(:hits) { |slide| slide.hits.to_i }
      expose :user, :using => APIEntities::User
      # replies only exposed when a single slide is fetched
      expose(:replies, :unless => { :collection => true }) do |model, opts|
        replies = model.replies
        replies = replies.unscoped if opts[:include_deleted]
        APIEntities::Reply.represent(replies.asc(:_id))
      end
    end

    class Node < Grape::Entity
      expose :id, :name, :slides_count, :summary, :section_id, :sort
      expose(:section_name) {|model, opts| model.section.try(:name) }
    end

    class Notification < Grape::Entity
      expose :id, :created_at, :updated_at, :read
      expose(:mention, :if => lambda {|model, opts| model.is_a? ::Notification::Mention }) do |model, opts|
        # mode.mentionable_type could be "Reply" or "Slide"
        APIEntities.const_get(model.mentionable_type).represent model.mentionable
      end
      expose(:reply, :if => lambda {|model, opts| model.is_a? ::Notification::SlideReply }) do |model, opts|
        APIEntities::Reply.represent model.reply
      end
    end
  end
end

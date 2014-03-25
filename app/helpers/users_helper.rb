# coding: utf-8
require "digest/md5"
module UsersHelper
  # 生成用户 login 的链接，user 参数可接受 user 对象或者 字符串的 login
  def user_name_tag(user, options = {})
    return "匿名" if user.blank?
    link = options[:link] || true
    if (user.class == "".class)
      login = user
      name = login
    else if(user.class == 1.class)
           user= User.find(user);
           login = user.login
           name = user.name
         else
           login = user.login
           name = user.name
          end
    end

    name ||= login
    options['data-name'] = name
    if link
      link_to(login, user_path(login.downcase), options)
    else
      raw login
    end
  end

  def user_avatar_width_for_size(size)
    case size
      when :normal then 48
      when :small then 16
      when :large then 64
      when :big then 120
      else size
    end
  end

  def user_avatar_size_name_for_2x(size)
    case size
      when :normal then :large
      when :small then :normal
      when :large then :big
      when :big then :big
      else size
    end
  end

  def user_avatar_tag(user, size = :normal, opts = {})
    link = opts[:link] || false
    alt = opts[:alt] || false
    custom_class = opts[:class] || ''
    width = user_avatar_width_for_size(size)

    if user.blank?
      # hash = Digest::MD5.hexdigest("") => d41d8cd98f00b204e9800998ecf8427e
      return image_tag("avatar/#{size}.png", :class => "#{custom_class}")
    end
    if(user.class == 1.class)
      user= User.find(user);
    end
    if user[:avatar].blank?
      default_url = asset_path("avatar/#{size}.png")
      img_src = "#{Setting.gravatar_proxy}/avatar/#{user.email_md5}.png"
      img = image_tag(img_src, :class => "#{custom_class}", :style => "width:#{width}px;height:#{width}px;")
    else
      img = image_tag(user.avatar.url(user_avatar_size_name_for_2x(size)), :class => "#{custom_class}", :style => "width:#{width}px;height:#{width}px;")
    end

    if link
      raw %(<a alt="#{alt}" href="#{user_path(user.login)}">#{img}</a>)
    else
      raw img
    end
  end

  def render_user_join_time(user)
    I18n.l(user.created_at.to_date, :format => :long)
  end

  def render_user_tagline(user)
    user.tagline
  end

  def render_user_github_url(user)
    link_to(user.github_url, user.github_url, :target => "_blank", :rel => "nofollow")
  end

  def render_user_personal_website(user)
    website = user.website[/^https?:\/\//] ? user.website : "http://" + user.website
    link_to(website, website, :target => "_blank", :class => "url", :rel => "nofollow")
  end

  def render_user_level_tag(user)
    if admin?(user)
      content_tag(:span, t("common.admin_user"), :class => "label label-warning")
    elsif wiki_editor?(user)
      content_tag(:span, t("common.vip_user"), :class => "label label-success")
    elsif user.newbie?
      content_tag(:span, t("common.newbie_user"), :class => "label label-default")
    else
      content_tag(:span, t("common.normal_user"), :class => "label label-info")
    end
  end

  def user_follow_tag(follower_user)
    return "" if current_user.blank?
    return "" if follower_user.blank?
    return "" if current_user.id.equal?(follower_user.id)
    icon = content_tag(:i, "", :class => "fa fa-check")
    link_title = "关注"
    if current_user and current_user.follower_ids.include?(follower_user.id)
      icon = content_tag(:i, "", :class => "fa fa-check-circle")
      link_title = "取消关注"
    end
    follow_label = raw "#{icon} <span>#{link_title}</span>"
    raw "#{link_to(follow_label, "#", :onclick => "return Users.follow(this);", 'data-id' => follower_user.id, :class => "btn txt-color-white bg-color-teal btn-sm", :title => link_title, :rel => "twipsy")}"
  end

end

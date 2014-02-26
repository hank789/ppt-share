# coding: utf-8
require 'digest/md5'
module SlidesHelper
  def format_slide_body(text)
    MarkdownSlideConverter.format(text)
  end

  def slide_use_readed_text(state)
    case state
    when true
      t("slides.have_no_new_reply")
    else
      t("slides.has_new_replies")
    end
  end

	def slide_download_tag(slide)
		return "" if slide.blank?
		return "" if slide.slide.blank?
		title = raw "#{content_tag(:i, "", :class => "icon-download-alt")} <span>Download</span>"
		link_to(title, download_attach_url(slide.slide), class:"btn btn-large btn-success")
	end

  def slide_favorite_tag(slide)
    return "" if current_user.blank?
		return "" if slide.blank? 
		return "" if owner?(slide)
    icon = content_tag(:i, "", :class => "icon small_bookmark")
    link_title = "收藏"
    if current_user and current_user.favorite_slide_ids.include?(slide.id)
      icon = content_tag(:i, "", :class => "icon small_bookmarked")
      link_title = "取消收藏"
    end
		favorite_label = raw "#{icon} <span>#{link_title}</span>"
    raw "#{link_to(favorite_label, "#", :onclick => "return Slides.favorite(this);", 'data-id' => slide.id, :class => "btn", :title => link_title, :rel => "twipsy")}"
  end

  def slide_follow_tag(slide)
    return "" if current_user.blank?
    return "" if slide.blank?
    return "" if owner?(slide)
    class_name = "follow"
    if slide.follower_ids.include?(current_user.id)
      class_name = "followed"
    end
    icon = content_tag("i", "", :class => "icon small_#{class_name}")
    link_to raw([icon,"关注"].join(" ")), "#", :onclick => "return Slides.follow(this);",
                        'data-id' => slide.id,
                        'data-followed' => (class_name == "followed"),
                        :rel => "twipsy"
  end

  def slide_title_tag(slide)
    return t("slides.slide_was_deleted") if slide.blank?
    link_to(slide.title, slide_path(slide), :title => slide.title)
  end
  
  def slide_excellent_tag(slide)
    return "" if !slide.excellent?
    raw %(<i class="icon small_cert_on" title="精华贴"></i>)
  end

  def render_slide_last_reply_time(slide)
    l((slide.replied_at || slide.created_at), :format => :short)
  end

  def render_slide_created_at(slide)
    timeago(slide.created_at, :class => "published")
  end

  def render_slide_last_be_replied_time(slide)
    timeago(slide.replied_at)
  end

  def render_slide_node_select_tag(slide)
    return if slide.blank?
    grouped_collection_select :slide, :node_id, Section.all,
                    :sorted_nodes, :name, :id, :name, {:value => slide.node_id,
                    :include_blank => true, :prompt => "选择节点"}, :style => "width:145px;"
  end
end

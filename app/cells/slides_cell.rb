# coding: utf-8
class SlidesCell < BaseCell

  def reply_help_block(opts = {})
    @full = opts[:full] || false
    render
  end

  def carousel(opts = {})
    @attach = Attach.find(opts[:attach_id]) unless opts[:attach_id].blank?
    @photos = @attach.photos.asc(:order_number) unless opts[:attach_id].blank?
    if @photos.first.present?
      image_str = @photos.first.image.to_s
      if image_str[-6..-1].index('_') == 0
        @img_str = image_str[0..-6]
      else
        @img_str = image_str[0..-7]
      end
    end


    render
  end

  def carousel_simple(opts = {})
    @attach = Attach.find(opts[:attach_id]) unless opts[:attach_id].blank?
    @photos = @attach.photos.asc(:order_number).limit(1) unless opts[:attach_id].blank?
    render
  end

  def sidebar_releated_slides(opts = {})
    @slide = opts[:slide]
    tags_objects = ActsAsTaggable::Tag.where(:name.in => @slide.tags, "tagged.object_class" => "Slide" ).all.to_a
    @slides = Array.new

    for tags_arr in tags_objects do
      for tag in tags_arr.tagged
        if tag['object_id'] != @slide.id
          @slides.insert(tag['object_id'], Slide.find_by_id(tag['object_id']))
        end
      end
    end
    @slides = @slides.compact
    render
  end

end

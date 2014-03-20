# coding: utf-8
module RepliesHelper
  def render_reply_at(reply)
    l(reply.created_at, :format => :short)
  end

  def reply_body_tag(reply_id)
    if(reply_id.class == 1.class)
      reply = Reply.find(reply_id)
      reply.body_html
    end
  end
end

# coding: utf-8
class SlidesCell < BaseCell

  def reply_help_block(opts = {})
    @full = opts[:full] || false
    render
  end

	def carousel(opts = {})
		@attach = Attach.find(opts[:attach_id])
		render
	end

end

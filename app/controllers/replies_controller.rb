# coding: utf-8
class RepliesController < ApplicationController

  load_and_authorize_resource :reply

  before_filter :find_slide

  def create

    @reply = Reply.new(reply_params)
    @reply.slide_id = @slide.id
    @reply.user_id = current_user.id

    if @reply.save
      current_user.read_slide(@slide)
      @reply.create_activity :create, owner: current_user, recipient: @slide.user, parameters: {:slide_id => @slide.id}
      puts @reply.mentioned_user_ids
      if @reply.mentioned_user_ids
        for mentioned_user_id in @reply.mentioned_user_ids
          @reply.create_activity :mention, owner: current_user, recipient: User.find(mentioned_user_id), parameters: {:slide_id => @slide.id}
        end
      end
      @msg = t("slides.reply_success")
    else
      @msg = @reply.errors.full_messages.join("<br />")
    end
  end

  def edit
    @reply = Reply.find(params[:id])
    drop_breadcrumb(t("menu.slides"), slides_path)
    drop_breadcrumb t("reply.edit_reply")
  end

  def update
    @reply = Reply.find(params[:id])

    if @reply.update_attributes(reply_params)
      @reply.create_activity :update, owner: current_user, recipient: @slide.user, parameters: {:slide_id => @slide.id}
      redirect_to(slide_path(@reply.slide_id), :notice => '回帖更新成功.')
    else
      render :action => "edit"
    end
  end

  def destroy
    @reply = Reply.find(params[:id])
    if @reply.destroy
      @reply.create_activity :destroy, owner: current_user, recipient: @slide.user, parameters: {:slide_id => @slide.id}
      redirect_to(slide_path(@reply.slide_id), :notice => '回帖删除成功.')
    else
      redirect_to(slide_path(@reply.slide_id), :alert => '程序异常，删除失败.')
    end
  end

  protected

  def find_slide
    @slide = Slide.find(params[:slide_id])
  end

  def reply_params
    params.require(:reply).permit(:body)
  end

end

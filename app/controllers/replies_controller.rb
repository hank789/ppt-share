# coding: utf-8
class RepliesController < ApplicationController

  load_and_authorize_resource :reply

  before_filter :find_attach
  def create

    @reply = Reply.new(reply_params)
    @reply.attach_id = @attach.id
    @reply.user_id = current_user.id

    if @reply.save
      current_user.read_attach(@attach)
      @msg = t("slides.reply_success")
    else
      @msg = @reply.errors.full_messages.join("<br />")
    end
  end

  def edit
    @reply = Reply.find(params[:id])
    drop_breadcrumb(t("menu.attachs"), attachs_path)
    drop_breadcrumb t("reply.edit_reply")
  end

  def update
    @reply = Reply.find(params[:id])

    if @reply.update_attributes(reply_params)
      redirect_to(attach_path(@reply.attach_id), :notice => '回帖更新成功.')
    else
      render :action => "edit"
    end
  end
  
  def destroy
    @reply = Reply.find(params[:id])
    if @reply.destroy
      redirect_to(attach_path(@reply.attach_id), :notice => '回帖删除成功.')
    else
      redirect_to(attach_path(@reply.attach_id), :alert => '程序异常，删除失败.')
    end
  end

  protected

  def find_attach
    @attach = Attach.find(params[:attach_id])
  end
  
  def reply_params
    params.require(:reply).permit(:body)
  end

end

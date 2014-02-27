class AttachsController < ApplicationController
  # load_and_authorize_resource :only => [:create, :destroy]
  before_filter :require_user
	#require 'open-uri'
	
	def create
			@attach = current_user.attachs.new
			@attach.file= params[:file]
      @attach.slide_id = params[:slide_id]
			if @attach.save
			#Attach.new({:url => @b}).save
				render :text => @attach._id 
			else 
				render :text => false 
			end
	end 

	def download
		unless current_user
			redirect_to new_user_session_path 	
		else
			attach = Attach.find(params[:id])
			slide = Slide.find(attach.slide_id)
			key = attach.file.to_s.split("#{Setting.qiniu_bucket_domain}/")
			if key.length == 2 
				stat = Qiniu::RS.stat(Setting.qiniu_bucket, key[1])
				slide.downloads.incr(1)
				dlToken = Qiniu::RS.generate_download_token :expires_in => 5, :pattern => attach.file
				file_name = slide.title + File.extname(key[1]) 
				#render :text => "#{attach.file}?token=#{dlToken}"
				data = open("#{attach.file}?token=#{dlToken}")
	  		send_data data.read, :filename => file_name, :type => stat["mimeType"], :disposition => 'attachment', :stream => 'true', :buffer_size => '4096'
			end
		end

	end

	def carousel
		render :text => 1
		@attach = Attach.find(params[:id])
	  #respond_to do |format|
		format.json { render :json => {:success => true, :html => (render_to_string 'attachs/carousel.html.erb')} }
		format.html { }
		#end
		#box = render_cell :slides, :carousel, params[:id]
		#render :text => box.to_s
	end

end

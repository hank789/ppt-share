class AttachsController < ApplicationController
  load_and_authorize_resource :only => [:destroy]
	#require 'open-uri'

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

end

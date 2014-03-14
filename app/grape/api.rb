require "entities"
require "helpers"

module MakeSlide
  class API < Grape::API
    prefix "api"
    format :json

    helpers APIHelpers

    # Authentication:
    # APIs marked as 'require authentication' should be provided the user's private token,
    # either in post body or query string, named "token"

    resource :slides do

      # Get active slides list
      # params[:page]
      # params[:per_page]: default is 30
      # Example
      #   /api/slides/index.json?page=1&per_page=15
      get do
        @slides = Slide.last_actived.includes(:user).paginate(:page => params[:page], :per_page => params[:per_page]||30)
        present @slides, :with => APIEntities::Slide
      end

      # Get active slides of the specified node
      # params[:id]: node id
      # other params are same to those of slides#index
      # Example
      #   /api/slides/node/1.json?size=30
      get "node/:id" do
        @node = Node.find(params[:id])
        @slides = @node.slides.last_actived
          .limit(page_size)
          .includes(:user)
        present @slides, :with => APIEntities::Slide
      end

      # Post a new slide
      # require authentication
      # params:
      #   title
      #   body
      #   node_id
      post do
        authenticate!
        @slide = current_user.slides.new(:title => params[:title], :body => params[:body])
        @slide.node_id = params[:node_id]
        @slide.save!
        #TODO error handling
      end

      # Get slide detail
      # Example
      #   /api/slides/1.json
      get ":id" do
        @slide = Slide.includes(:replies).find_by_id(params[:id])
        @slide.hits.incr(1)
        present @slide, :with => APIEntities::DetailSlide
      end

      # Post a new reply
      # require authentication
      # params:
      #   body
      # Example
      #   /api/slides/1/replies.json
      post ":id/replies" do
        authenticate!
        @slide = Slide.find(params[:id])
        @reply = @slide.replies.build(:body => params[:body])
        @reply.user_id = current_user.id
        @reply.save
      end

      # Follow a slide
      # require authentication
      # params:
      #   NO
      # Example
      #   /api/slides/1/follow.json
      post ":id/follow" do
        authenticate!
        @slide = Slide.find(params[:id])
        @slide.push_follower(current_user.id)
      end

      # Unfollow a slide
      # require authentication
      # params:
      #   NO
      # Example
      #   /api/slides/1/unfollow.json
      post ":id/unfollow" do
        authenticate!
        @slide = Slide.find(params[:id])
        @slide.pull_follower(current_user.id)
      end

      # Add/Remove a slide to/from favorite
      # require authentication
      # params:
      #   type(optional) default is empty, set it unfavoritate to remove favorite
      # Example
      #   /api/slides/1/favorite.json
      post ":id/favorite" do
        authenticate!
        if params[:type] == "unfavorite"
          current_user.unfavorite_slide(params[:id])
        else
          current_user.favorite_slide(params[:id])
        end
      end
    end

    resource :nodes do
      # Get a list of all nodes
      # Example
      #   /api/nodes.json
      get do
        present Node.all, :with => APIEntities::Node
      end
    end

    # Mark a slide as favorite for current authenticated user
    # Example
    # /api/user/favorite/qichunren/8.json?token=232332233223:1
    resource :user do
      put "favorite/:user/:slide" do
        authenticate!
        current_user.favorite_slide(params[:slide])
      end
    end

    resource :users do
      # Get top 20 hot users
      # Example
      # /api/users.json
      get do
        @users = User.hot.limit(20)
        present @users, :with => APIEntities::DetailUser
      end
      
      # Get temp_access_token, this key is use for Faye client channel
      # Example
      # /api/users/temp_access_token?token=232332233223:1
      get "temp_access_token" do
        authenticate!
        present ({ :temp_access_token => current_user.temp_access_token }).to_json
      end

      # Get a single user
      # Example
      #   /api/users/qichunren.json
      get ":user" do
        @user = User.where(:login => /^#{params[:user]}$/i).first
        present @user, :slides_limit => 5, :with => APIEntities::DetailUser
      end


      # List slides for a user
      get ":user/slides" do
        @user = User.where(:login => /^#{params[:user]}$/i).first
        @slides = @user.slides.recent.limit(page_size)
        present @slides, :with => APIEntities::UserSlide
      end

      # List favorite slides for a user
      get ":user/slides/favorite" do
        @user = User.where(:login => /^#{params[:user]}$/i).first
        @slides = Slide.find(@user.favorite_slide_ids)
        present @slides, :with => APIEntities::Slide
      end
    end

    # List all cool sites
    # Example
    # GET /api/sites.json
    resource :sites do
      get do
        @site_nodes = SiteNode.all.includes(:sites).desc('sort')
        @site_nodes.as_json(:except => :sort, :include => {
          :sites => {
            :only => [:name, :url, :desc, :favicon, :created_at]
          }
        })
      end
    end

  end
end

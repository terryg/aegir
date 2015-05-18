require 'sinatra'
require 'oauth'
require 'haml'
require 'omniauth'
require 'omniauth-twitter'
require 'omniauth-tumblr'
require 'tumblr_client'
require 'json'

require './brog_post'

class App < Sinatra::Base
	use Rack::Session::Cookie, :key => 'rack.session', :secret => 'formica-bituminous-lahey-this-is-the-patently-secret-thing'
	enable :logging

  AEGIR_TAG = "aegir-bot"

  use OmniAuth::Builder do
    provider :tumblr, ENV['TUMBLR_CONSUMER_KEY'], ENV['TUMBLR_CONSUMER_SECRET']
    provider :twitter, ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET']
  end

  get '/' do
    @current_user = current_user
    @users = UserProfile.all
    @brog_post = BrogPost.new
    haml :index
  end

  get '/user/:name' do
    @current_user = current_user
    @user = UserProfile.first(:name => params[:name])

    if @user
      Tumblr.configure do |config|
        config.consumer_key = ENV['TUMBLR_CONSUMER_KEY']
        config.consumer_secret = ENV['TUMBLR_CONSUMER_SECRET']
        config.oauth_token = @user.access_token
        config.oauth_token_secret = @user.access_token_secret
      end

      client = Tumblr::Client.new

      @batches = []
      response = client.posts("#{@user.name}.tumblr.com", :tag => AEGIR_TAG)
      response["posts"].each do |post|
        post["tags"].each do |t|
          @batches << t
        end
      end

      @batches.uniq!
      @batches.delete(AEGIR_TAG)
    end

    haml :user
  end

  get '/user/:name/:batch' do
    @current_user = current_user
    @user = UserProfile.first(:name => params[:name])
    
    if @user
      Tumblr.configure do |config|
        config.consumer_key = ENV['TUMBLR_CONSUMER_KEY']
        config.consumer_secret = ENV['TUMBLR_CONSUMER_SECRET']
        config.oauth_token = @user.access_token
        config.oauth_token_secret = @user.access_token_secret
      end

      client = Tumblr::Client.new

      response = client.posts("#{@user.name}.tumblr.com", :tag => [AEGIR_TAG, params[:batch]])
      @posts = response["posts"] if response
      @posts ||= []
    end

    haml :batch
  end

  post '/new' do
    @current_user = current_user

    if @current_user
      Tumblr.configure do |config|
        config.consumer_key = ENV['TUMBLR_CONSUMER_KEY']
        config.consumer_secret = ENV['TUMBLR_CONSUMER_SECRET']
        config.oauth_token = @current_user.access_token
        config.oauth_token_secret = @current_user.access_token_secret
      end

      client = Tumblr::Client.new

      puts "***** made client"

      body_text = params[:body]
    
      timestamp = Time.now

      puts "**** Starting..."

      resp = client.text("#{@current_user.name}.tumblr.com", {
                           :title => timestamp.strftime("%Y-%m-%d %H:%M"),
                           :body => body_text,
                           :tags => [AEGIR_TAG, "batch#{params[:batch_id]}"]})


      puts "**** Done."
    else
      puts "**** Current User is nil!"
    end


    redirect '/'
  end

  get '/list/:name' do

  end

  get '/auth/:provider/callback' do
    auth = auth_hash

    user = UserProfile.first_or_create({:uid => auth[:uid]}, {
                                         :uid => auth[:uid],
                                         :name => auth[:info][:name],
                                         :provider => params[:provider],
                                         :created_at => Time.now,
                                         :updated_at => Time.now,
                                         :access_token => auth[:credentials][:token],
                                         :access_token_secret => auth[:credentials][:secret] })
    
    session[:uid] = user.uid


		puts "*** provider is #{params[:provider]}"

		if params[:provider] == 'tumblr'
      @blogs = []
      auth[:extra][:raw_info][:blogs].each do |b|
        @blogs << b[:name]
      end

			puts "$$$ blog size is #{@blogs.size}"

      if @blogs.size > 1
        haml :tumblr
      else
        redirect '/'
		  end
		else
      redirect '/'
		end
  end

  post '/tumblr' do
		blogname = params[:blogname]  

		puts "XXXX blogname is #{blogname}"
		puts "XXXX anything else?"
    puts params

		user = current_user

		puts "CCCC #{user.uid}"


		unless user.nil?
			user.uid = blogname
			user.name = blogname
			if user.save
				session[:uid] = blogname
			end
    end
    
    redirect '/'
  end

  get '/auth/failure' do
    redirect '/'
  end

  get '/signout' do
    session[:uid] = nil
    redirect '/'
  end
  
  private

  def auth_hash
    request.env['omniauth.auth']
  end

  def current_user
		puts "SSSSSSSSS session has #{session[:uid]}"
    @current_user ||= UserProfile.first(:uid => session[:uid]) if session[:uid]
  end

  def authenticate
    unless @current_user
      redirect '/'
      return false
    end
  end

end

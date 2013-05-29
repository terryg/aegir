require 'sinatra'
require 'oauth'
require 'haml'
require 'omniauth'
require 'omniauth-twitter'
require 'omniauth-tumblr'
require 'tumblr_client'

require './brog_post'

class App < Sinatra::Base
  enable :sessions

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

      @posts = client.posts("#{@user.name}.tumblr.com")
    end

    haml :user
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
      
      body_text = params[:body]
    
      timestamp = Time.now

      client.text("#{session[:name]}.tumblr.com", {
                  :title => timestamp.strftime("%Y-%m-%d %H:%M"),
                  :body => body_text,
                  :tags => ["aegir-bot", "batch#{params[:batch_id]}"]})
    end

    redirect '/'
  end

  get '/list/:name' do

  end

  get '/auth/:provider/callback' do
    auth = auth_hash
    session[:uid] = auth[:uid]
    session[:name] = auth[:info][:name]
    session[:provider]= params[:provider]
    session[:token] = auth[:credentials][:token]
    session[:secret] = auth[:credentials][:secret]
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
    @current_user ||= UserProfile.first(:uid => session[:uid]) if session[:uid]
  end

  def authenticate
    unless @current_user
      redirect '/'
      return false
    end
  end

end

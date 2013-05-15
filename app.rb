require 'sinatra'
require 'oauth'
require 'haml'
require 'omniauth'
require 'omniauth-twitter'
require 'omniauth-tumblr'
require 'tumblr_client'

require './user_profile'
require './brog_post'

class App < Sinatra::Base
  enable :sessions

  use OmniAuth::Builder do
    provider :tumblr, ENV['TUMBLR_CONSUMER_KEY'], ENV['TUMBLR_CONSUMER_SECRET']
    provider :twitter, ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET']
  end

  get '/' do
    @current_user = current_user
    @brog_post = BrogPost.new
    haml :index
  end

  post '/new' do
    @current_user = current_user

    Tumblr.configure do |config|
      config.consumer_key = ENV['TUMBLR_CONSUMER_KEY']
      config.consumer_secret = ENV['TUMBLR_CONSUMER_SECRET']
      config.oauth_token = @current_user.access_token
      config.oauth_token_secret = @current_user.access_token_secret
    end

    client = Tumblr::Client.new

    body_text = params[:body]
    body_text << "#batch#{params[:batch_id]}"
    body_text << "#aegir-bot"

    client.text("#{@current_user.name}.tumblr.com", {:title => "2013-05-13",
                  :body => body_text})

    redirect '/'
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
                                         :access_token_secret => auth[:credentials][:secret]})
    session[:id] = user.id
    redirect '/'
  end

  get '/auth/failure' do
    redirect_to '/', :notice => "Sorry, something went wrong. Please try again."
  end

  get '/signout' do
    session[:uid] = nil
    redirect_to '/', :notice => "Signed out!"
  end
  
  private

  def auth_hash
    request.env['omniauth.auth']
  end

  def current_user
    @current_usser ||= UserProfile.get(session[:id]) if session[:id]
  end

  def authenticate
    unless @current_user
      redirect_to "/"
      return false
    end
  end

end

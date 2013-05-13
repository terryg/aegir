require 'sinatra'
require 'oauth'
require 'haml'
require 'omniauth'
require 'omniauth-twitter'
require 'omniauth-tumblr'

require './user_profile'
require './brog_post'

class App < Sinatra::Base
  enable :sessions

  use OmniAuth::Builder do
    provider :tumblr, ENV['TUMBLR_CONSUMER_KEY'], ENV['TUMBLR_CONSUMER_SECRET']
    provider :twitter, ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET']
  end

  get '/' do
    @current_user = UserProfile.find(session[:id])
    @brog_post = BrogPost.new
    haml :index
  end

  post '/new' do

  end

  get '/auth/:provider/callback' do
    auth = request.env['omniauth.auth']
    user = UserProfile.first_or_create({:uid => auth[:uid]}, {
                                         :uid => auth[:uid],
                                         :name => auth[:info][:name],
                                         :provider => params[:provider],
                                         :created_at => Time.now,
                                         :updated_at => Time.now,
                                         :consumer_key => auth['token'],
                                         :consumer_secret => auth['secret']})
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
    @current_user ||= UserProfile.find(session[:uid]) if session[:uid]
  end

  def authenticate
    unless @current_user
      redirect_to "/"
      return false
    end
  end

end

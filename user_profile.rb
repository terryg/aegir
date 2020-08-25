# frozen_string_literal: true

# A user model
class UserProfile
  include DataMapper::Resource

  property :id, Serial
  property :uid, String
  property :name, String
  property :provider, String
  property :created_at, DateTime
  property :updated_at, DateTime
  property :access_token, String
  property :access_token_secret, String
end

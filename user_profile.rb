class UserProfile
  include DataMapper::Resource

  property :id, Serial
  property :uid, String
  property :name, String
  property :provider, String
  property :created_at, DateTime
  property :updated_at, DateTime
  property :consumer_key, String
  property :consumer_secret, String
end

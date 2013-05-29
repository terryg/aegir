
require "rubygems"

require "haml"
require "pg"
require "dm-core"
require "dm-validations"
require "dm-migrations"
require "oauth"
require "omniauth"
require "omniauth-twitter"
require "omniauth-tumblr"

require "./user_profile"

DataMapper.setup(:default, (ENV['HEROKU_POSTGRESQL_GOLD_URL'] || "postgres://localhost:5432/aegir_development"))
DataMapper.auto_upgrade!


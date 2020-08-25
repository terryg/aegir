# frozen_string_literal: true

require 'rubygems'

require 'haml'
require 'pg'
require 'dm-core'
require 'dm-validations'
require 'dm-migrations'
require 'oauth'
require 'omniauth'
require 'omniauth-twitter'
require 'omniauth-tumblr'

require './user_profile'

DataMapper.setup(:default, ENV['DATABASE_URL'])
DataMapper.auto_upgrade!

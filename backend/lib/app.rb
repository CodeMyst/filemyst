# frozen_string_literal: true

require 'sinatra'
require 'sinatra/json'
require 'sinatra/activerecord'
require_relative 'models'

set :database, { adapter: 'sqlite3', database: 'filemyst.sqlite3' }

get '/' do
  puts User.count

  json({ message: 'hello world' })
end

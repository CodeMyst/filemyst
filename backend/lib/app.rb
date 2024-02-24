# frozen_string_literal: true

require 'sinatra'
require 'sinatra/json'
require 'sinatra/activerecord'
require 'jwt'
require 'yaml'
require_relative 'models'

set :database, { adapter: 'sqlite3', database: 'filemyst.sqlite3' }

config = YAML.load_file('config.yml', symbolize_names: true)

User.create(
  username: config[:admin_username],
  password: config[:admin_password],
  password_confirmation: config[:admin_password]
)

post '/login' do
  data = JSON.parse(request.body.read, symbolize_names: true)

  user = User.find_by username: data[:username]

  if user&.authenticate(data[:password])
    payload = { username: user.username }
    token = JWT.encode(payload, config[:jwt_secret], 'HS256')

    json({ access_token: token })
  else
    401
  end
end

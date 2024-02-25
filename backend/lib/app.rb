# frozen_string_literal: true

require 'sinatra'
require 'sinatra/json'
require 'sinatra/activerecord'
require 'jwt'
require 'yaml'
require_relative 'models'

set :database, { adapter: 'sqlite3', database: 'filemyst.sqlite3' }

config = YAML.load_file('config.yml', symbolize_names: true)
files_path = File.expand_path(config[:files_path])

# create the files dir if doesn't exist
Dir.mkdir(files_path) unless Dir.exist?(files_path)

# create the admin user if doesn't exist
User.create(
  username: config[:admin_username],
  password: config[:admin_password],
  password_confirmation: config[:admin_password]
)

# returns the file size of a file or a directory, it it's a directory it recurses the contents
def get_file_size(path)
  if File.directory?(path)
    Dir["#{path}/**/*"].select { |f| File.file?(f) }.sum { |f| File.size(f) }
  else
    File.size(path)
  end
end

before do
  headers(
    {
      'Access-Control-Allow-Origin' => config[:frontend_url]
    }
  )
end

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

get '/*' do
  file = File.join(files_path, params[:splat])

  return 404 unless File.exist?(file)

  if File.directory?(file)
    dir_entries = Dir.entries(file)
                     .reject { |e| ['.', '..'].include? e }
                     .sort_by { |e| [File.directory?(File.join(file, e)) ? 0 : 1, e] }

    files = dir_entries.map do |entry|
      full_path = File.join(file, entry)
      {
        name: entry,
        size: get_file_size(full_path),
        last_modified: File.mtime(full_path),
        is_dir: File.directory?(full_path)
      }
    end

    json(files)
  else
    send_file file
  end
end

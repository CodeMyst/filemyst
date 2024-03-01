# frozen_string_literal: true
#
require 'dotenv/load'
require 'sinatra'
require 'sinatra/json'
require 'sinatra/activerecord'
require 'jwt'
require 'fileutils'
require_relative 'models'

FILES_PATH = 'files'

set :database, { adapter: 'sqlite3', database: 'filemyst.sqlite3' }
set :port, ENV['PORT']

# create the files and trash dir if doesn't exist
Dir.mkdir(FILES_PATH) unless Dir.exist?(FILES_PATH)
Dir.mkdir(File.join(FILES_PATH, '.trash')) unless Dir.exist?(File.join(FILES_PATH, '.trash'))

# create the admin user if doesn't exist
User.create(
  username: ENV['ADMIN_USERNAME'],
  password: ENV['ADMIN_PASSWORD'],
  password_confirmation: ENV['ADMIN_PASSWORD']
)

# returns the file size of a file or a directory, it it's a directory it recurses the contents
def get_file_size(path)
  if File.directory?(path)
    Dir["#{path}/**/*"].select { |f| File.file?(f) }.sum { |f| File.size(f) }
  else
    File.size(path)
  end
end

def logged_in?(request, jwt_secret)
  auth = request.env['HTTP_AUTHORIZATION']

  return false unless auth.present? && auth.start_with?('Bearer ')

  token = auth['Bearer '.length..]

  payload = JWT.decode(token, jwt_secret, true, { algorithm: 'HS256' })

  return false if User.find_by(username: payload.first['username']).nil?

  true
rescue JWT::DecodeError
  false
end

before do
  headers(
    {
      'Access-Control-Allow-Origin' => ENV['FRONTEND_URL'],
      'Access-Control-Allow-Methods' => %w[GET POST OPTIONS DELETE PUT],
      'Access-Control-Allow-Headers' => %w[Authorization]
    }
  )
end

options '/*' do
  200
end

post '/login' do
  data = JSON.parse(request.body.read, symbolize_names: true)

  user = User.find_by username: data[:username]

  if user&.authenticate(data[:password])
    payload = { username: user.username }
    token = JWT.encode(payload, ENV['JWT_SECRET'], 'HS256')

    json({ access_token: token })
  else
    401
  end
end

# index of files
get '/*' do
  file = File.join(FILES_PATH, params[:splat])

  return 404 unless File.exist?(file)

  is_logged_in = logged_in?(request, ENV['JWT_SECRET'])

  if File.directory?(file)
    return 403 if file.include?('.trash') && !is_logged_in

    dir_entries = Dir.entries(file)
                     .reject { |e| ['.', '..'].include? e }
                     .sort_by { |e| [File.directory?(File.join(file, e)) ? 0 : 1, e] }

    dir_entries.reject! { |e| e.start_with? '.' } unless is_logged_in

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
    attachment
    send_file file
  end
end

# upload files
post '/*' do
  return 403 unless logged_in?(request, ENV['JWT_SECRET'])

  path = File.join(FILES_PATH, params[:splat])

  return 404 unless File.exist?(path) && File.directory?(path)

  files = params[:files]

  files.each do |file|
    temp_file = file[:tempfile]
    name = file[:filename]
    FileUtils.mv(temp_file.path, File.join(path, name))
  end

  200
end

# delete files
delete '/*' do
  return 403 unless logged_in?(request, ENV['JWT_SECRET'])

  path = File.join(FILES_PATH, params[:splat])

  return 404 unless File.exist?(path)

  FileUtils.mv(path, File.join(FILES_PATH, '.trash', File.basename(path)))

  200
end

# rename files
put '/*' do
  return 403 unless logged_in?(request, ENV['JWT_SECRET'])

  dir = File.dirname(params[:splat].first)
  new_name = params[:new_name]

  return 400 unless params[:new_name]

  prev_path = File.join(FILES_PATH, params[:splat])

  return 404 unless File.exist?(prev_path)

  new_path = File.join(FILES_PATH, File.join(dir, new_name))

  FileUtils.mv(prev_path, new_path)

  200
end

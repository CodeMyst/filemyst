# frozen_string_literal: true

require 'sinatra'
require 'sinatra/json'

get '/' do
  json({ message: 'hello world' })
end

require "sinatra"
require "sinatra/content_for"
require "tilt/erubis"
require "rack"
require "json"
require "redcarpet"


configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(64)
end

before do 
  @root  = File.expand_path("..", __FILE__)
  @files = Dir.children('data')
  @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
end

helpers do
  def remove_ext(file_name)
    File.basename(file_name, ".*")
  end 
end

get '/' do
  erb :index, layout: :layout
end

get '/:file_name' do
  @file_name = params[:file_name]

  if @files.include? @file_name
    headers["Content-Type"] = "text/plain"
    File.read("data/#{@file_name}")
  else
    session[:error] = "#{@file_name} does not exist."
    redirect '/'
  end
end
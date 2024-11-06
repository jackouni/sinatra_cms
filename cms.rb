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
end

helpers do
  def remove_ext(file_name)
    File.basename(file_name, ".*")
  end 

  def markdown_to_html(md_file)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    markdown.render(md_file)
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
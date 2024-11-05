require "sinatra"
require "sinatra/content_for"
require "tilt/erubis"
require "rack"
require "json"

before do 
  @root = File.expand_path("..", __FILE__)
  @files = Dir.children('data')
end

helpers do
  def remove_ext(file_name)
    File.basename(file_name, ".*")
  end
end



get '/' do
  erb :home, layout: :layout
end

get '/:file_name' do
  @file_name = params[:file_name]

  if @files.include? @file_name
    headers["Content-Type"] = "text/plain"
    File.read("data/#{@file_name}")
  else
    redirect '/'
  end
end
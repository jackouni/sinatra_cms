require "sinatra"
require "sinatra/content_for"
require "tilt/erubis"
require "rack"
require "json"

before do 
  @files = Dir.children('data')
end

get '/' do
  erb :home, layout: :layout
end

get '/:file_name' do 
  file_names = @files.map do |file_name|
    File.basename(file_name, ".*")
  end

  if file_names.include? params[:file_name]
    @content = File.readlines("data/#{params[:file_name]}")
    erb :contents, layout: :layout
  else
    redirect '/'
  end
end
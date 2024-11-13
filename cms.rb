require "sinatra"
require "sinatra/content_for"
require "tilt/erubis"
require "rack"
require "json"
require "redcarpet"
require "yaml"
require 'bcrypt'


configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(64)
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def file_path(file_name)
  File.join(data_path, file_name)
end

def hashed_password(hash)
  BCrypt::Password.new(hash)
end

def load_yaml(file_name)
  if File.extname(file_name) == ".yaml"
    YAML.load_file(data_path + "/" + file_name)
  end
end

def valid_credentials(username, password)
  load_yaml("users.yaml").any? do |user, hash| 
    user == username && 
    BCrypt::Password.new(hash) == password 
  end
end

before do
  @root  = File.expand_path("..", __FILE__)
end

helpers do
  def remove_ext(file_name)
    File.basename(file_name, ".*")
  end 

  def render_markdown(content)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    markdown.render(content)
  end

  def load_file_contents(path)
    content = File.read(path)

    case File.extname(path)
    when ".txt" then headers["Content-Type"] = "text/plain"
    when ".md"  then content = render_markdown(content)
    end

    content
  end

  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end

  def delete_document(name)
    File.delete(File.join(data_path, name))
  end

  def valid_file_name?(name)
    name.size > 0
  end

  def user_signed_in?
    session.key?(:user)
  end

  def required_signed_in_user
    unless user_signed_in?
      session[:message] = "You must be signed in to do that."
      redirect "/" 
    end
  end
end

# HOME/INDEX PAGE
get '/' do
  @files = Dir.children(data_path)
  erb :index, layout: :layout
end

# VIEW FILE
get '/view/:file_name' do
  @file_name = params[:file_name]
  file_path = file_path(@file_name)

  if File.exist?(file_path)
    load_file_contents(file_path)
  else
    session[:message] = "#{@file_name} does not exist."
    redirect '/'
  end
end

# EDITING PAGE FOR A FILE
get '/edit/:file_name' do
  required_signed_in_user

  @file_name = params[:file_name]
  file_path = File.join(data_path, @file_name)

  if File.exist?(file_path)
    @file_contents = File.read(file_path)
    erb :edit, layout: :layout
  else
    session[:message] = "#{@file_name} does not exist."
    redirect '/'
  end
end

# SUBMIT EDITS FOR A FILE
post '/edit/:file_name' do
  required_signed_in_user

  @file_name = params[:file_name]
  file_path = File.join(data_path, @file_name)

  if File.exist?(file_path)
    session[:message] = "#{@file_name} successfully updated."
    File.write(file_path, params[:file_edit])
  else
    session[:message] = "#{@file_name} was not successfully updated."
  end

  redirect '/'
end

# CREATE FILE PAGE
get "/new" do
  required_signed_in_user

  erb :create_doc, layout: :layout
end 

# SUBMIT FILE CREATION
post "/create" do
  required_signed_in_user

  file_name = params[:doc_name].strip

  if valid_file_name?(file_name)
    create_document(file_name)
    session[:message] = "#{file_name} was successfully created."
    redirect "/"
  else
    session[:message] = "A name is required"
    status 422
  end

  erb :create_doc
end

# DELETE A FILE
get "/delete/:file_name" do
  required_signed_in_user

  file_name = params[:file_name] 
  file_path = File.join(data_path, file_name)

  if File.exist?(file_path)
    delete_document(file_name)
    session[:message] = "#{file_name} has been deleted"
  else
    session[:message] = "No file with that name was found."
  end

  redirect "/"
end

# USER LOGIN
get "/login" do
  erb :signin
end

# VALIDATE USER LOGIN CREDENTIALS
post "/user-validation" do 
  username = params[:username]
  password = params[:password]
  users = load_yaml "users.yaml"

  if valid_credentials(username, password)
    session[:user] = username
    session[:message] = "Welcome!"
    redirect "/"
  else
    session[:message] =  "Invalid credentials"
    redirect "/login"
  end
end

# SIGN OUT USER
get "/sign-out" do
  session.delete(:user)
  redirect "/login"
end
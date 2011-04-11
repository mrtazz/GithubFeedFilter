begin
require "bundler/setup"
rescue LoadError
  require 'rubygems'
  require "bundler/setup"
end
require 'sinatra/base'
require 'mustache/sinatra'
require 'yajl'
require 'net/http'
require 'uri'

class GithubFeedFilter

  class Server < Sinatra::Base
    register Mustache::Sinatra

    BASE = File.dirname(__FILE__)

    set :logging, :true
    set :root, BASE
    set :public, "public"
    require BASE + "/views/layout"

    set :mustache, {
      :views     => "#{BASE}/views/",
      :templates => "#{BASE}/templates/",
      :namespace => GithubFeedFilter
    }

    # http basic auth helpers
    helpers do

      def protected!
        unless authorized?
          redirect '/sign_in'
        end
      end

      def authorized?
        cookie = request.cookies["github_token"]
        # TODO: check for credentials
        true
      end

    end


    # index page
    get '/' do
      protected!
      @items = []
      mustache :index
    end

    get '/settings/?' do
      protected!
      mustache :settings
    end

    post '/settings/?' do
      protected!
      # TODO: save settings to redis
      redirect '/'
    end

    get '/sign_in/?' do
      mustache :signin
    end

    post '/sign_in/?' do
      # TODO: get watched repositories and merge with set in redis
      redirect '/'
    end


    # css
    #get '/css/style.css' do
      #content_type 'text/css', :charset => 'utf-8'
      #sass :stylesheet
    #end

  end
end

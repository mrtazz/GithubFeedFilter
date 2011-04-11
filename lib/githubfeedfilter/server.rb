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
    set :public, "#{BASE}/static"
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
        @auth ||=  Rack::Auth::Basic::Request.new(request.env)
        @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ['admin', 'admin']
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

    get '/sign_in/?' do
      mustache :signin
    end


    # css
    get '/css/style.css' do
      content_type 'text/css', :charset => 'utf-8'
      sass :stylesheet
    end

  end
end

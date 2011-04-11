begin
require "bundler/setup"
rescue LoadError
  require 'rubygems'
  require "bundler/setup"
end
require 'sinatra/base'
require 'mustache/sinatra'
require 'yajl'
require 'net/https'
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
        cookie = request.cookies["github_token"].split(":")
        res = github_authenticate(cookie[0], cookie[1])
        if res.code.to_i == 200
          return true
        else
          return false
        end
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
      cookie = request.cookies["github_token"].split(":")
      res = github_get_watched(cookie[0], cookie[1])
      @repos = Yajl::Parser.new().parse(res.body)["repositories"]
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

    private

    def github_authenticate(user, token)
      req = Net::HTTP::Get.new('https://github.com/api/v2/json/user/show')
      req.basic_auth(user+"/token", token)
      http = Net::HTTP.new("github.com", 443)
      http.use_ssl = true
      res = http.request(req)
    end

    def github_get_watched(user, token)
      req = Net::HTTP::Get.new("https://github.com/api/v2/json/repos/watched/#{user}")
      req.basic_auth(user+"/token", token)
      http = Net::HTTP.new("github.com", 443)
      http.use_ssl = true
      res = http.request(req)
    end

    def github_get_feed(user, token)
      url = "https://github.com/#{user}.private.json?token=#{token}"
      req = Net::HTTP::Get.new(url)
      req.basic_auth(user, token)
      http = Net::HTTP.new("github.com", 80)
      http.use_ssl = true
      res = http.request(req)
    end

    def handle_error(req, res)
      return false
    end

  end
end

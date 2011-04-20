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
require "redis"

# arrays for event categories
ALL       = ["all"]
PUSH      = ["PushEvent"]
ISSUES    = ["IssuesEvent"]
TAGS      = ["?TagEvent"]
COMMENTS  = ["IssueCommentEvent"]
PULLS     = ["PullRequestEvent"]
WIKI      = ["GollumEvent"]
FOLLOW    = ["FollowEvent"]


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

    def initialize(redis_host = "127.0.0.1", redis_port = 6380, *args)
      super *args
      @redis = Redis.new(:host => redis_host, :port => redis_port)
    end

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
      @repos = []
      full_repos = Yajl::Parser.new().parse(res.body)["repositories"]
      # TODO: check repos with settings in redis
      full_repos.foreach do |r|
        rep = {:name => r.name}
        if @redis.exists("#{cookie[0]}/#{r.name}")
          r_settings = @redis.smembers "#{cookie[0]}/#{r.name}"
          if (r_settings & ALL).length > 0
              rep[:all] = true
          else if (r_settings & PUSH).length > 0
              rep[:push] = true
          else if (r_settings & ISSUES).length > 0
              rep[:issues] = true
          else if (r_settings & TAGS).length > 0
              rep[:tags] = true
          else if (r_settings & COMMENTS).length > 0
              rep[:comments] = true
          else if (r_settings & PULLS).length > 0
              rep[:pulls] = true
          else if (r_settings & WIKI).length > 0
              rep[:wiki] = true
          end
        end
        @repos << rep
      end
      @repos.sort! { |a,b| a[:name].downcase <=> b[:name].downcase }
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
      http = Net::HTTP.new("github.com", 443)
      http.use_ssl = true
      res = http.request(req)
    end

  end
end

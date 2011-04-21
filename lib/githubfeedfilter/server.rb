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
require 'redis'

# arrays for event categories
ALL       = ["all"]
PUSH      = ["PushEvent", "DeleteEvent", "CreateEvent"]
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

    # http basic auth helpers
    helpers do

      def protected!
        unless authorized?
          redirect '/sign_in'
        end
      end

      def authorized?
        false
        unless request.cookies["github_token"].nil?
          cookie = request.cookies["github_token"].split(":")
          res = github_authenticate(cookie[0], cookie[1])
          if res.code.to_i == 200
            return true
          else
            return false
          end
        end
      end

    end

    def initialize(redis_host = "127.0.0.1", redis_port = 6379, *args)
      super *args
      @redis = Redis.new(:host => redis_host, :port => redis_port)
    end

    # index page
    get '/' do
      protected!
      cookie = request.cookies["github_token"].split(":")
      res = github_get_feed(cookie[0], cookie[1])
      feed = Yajl::Parser.new().parse(res.body)
      @items = []
      feed.each do |event|
        repo = event["repository"]["name"]
        if @redis.sismember("#{cookie[0]}/#{repo}", event["type"])
          @items << event
        end
      end
      mustache :index
    end

    # show settings page to the user
    get '/settings/?' do
      protected!
      cookie = request.cookies["github_token"].split(":")
      res = github_get_watched(cookie[0], cookie[1])
      @repos = []
      full_repos = Yajl::Parser.new().parse(res.body)["repositories"]
      # TODO: check repos with settings in redis
      full_repos.each do |r|
        rep = {:name => r["name"]}
        rep[:owner] = r["owner"]
        if @redis.exists("#{cookie[0]}/#{r["name"]}")
          r_settings = @redis.smembers "#{cookie[0]}/#{r["name"]}"
          if (r_settings & ALL).length > 0
              rep[:all] = true
          elsif (r_settings & PUSH).length > 0
              rep[:push] = true
          elsif (r_settings & ISSUES).length > 0
              rep[:issues] = true
          elsif (r_settings & TAGS).length > 0
              rep[:tags] = true
          elsif (r_settings & COMMENTS).length > 0
              rep[:comments] = true
          elsif (r_settings & PULLS).length > 0
              rep[:pulls] = true
          elsif (r_settings & WIKI).length > 0
              rep[:wiki] = true
          end
        end
        @repos << rep
      end
      @repos.sort! { |a,b| a[:name].downcase <=> b[:name].downcase }
      mustache :settings
    end

    # url to update single settings on check
    put '/settings/?' do
      protected!
      # TODO: save settings to redis
      redirect '/'
    end

    # get sign in page
    get '/sign_in/?' do
      mustache :signin
    end

    post '/sign_in/?' do
      # TODO: check github auth
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


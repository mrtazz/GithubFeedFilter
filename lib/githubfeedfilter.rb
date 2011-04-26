require "lib/githubfeedfilter/server"

VERSION = "0.1.0"

class GithubFeedFilter
  def self.app
    GithubFeedFilter::Server
  end
end

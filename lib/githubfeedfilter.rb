require "lib/githubfeedfilter/server"

class GithubFeedFilter
  def self.app
    GithubFeedFilter::Server
  end
end

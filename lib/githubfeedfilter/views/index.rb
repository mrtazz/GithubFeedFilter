class GithubFeedFilter
  module Views
    class Index < Layout

      def items
        ret = []
        now = DateTime.now
        @events.each do |i|
          ev = {}
          ev[:url] = i["url"]
          ev[:repourl] = i["repository"]["url"]
          ev[:actor] = i["actor"]
          ev[:date] = DateTime.parse(i["created_at"])
          hours, minutes = Date.day_fraction_to_time(now - ev[:date])
          if hours.to_i > 0
            ev[:time] = hours
            ev[:timeunit] = "hours"
          else
            ev[:time] = minutes
            ev[:timeunit] = "minutes"
          end
          ev[:action] = i["payload"]["action"] || ""
          ev[:number] = i["payload"]["number"] || ""
          ev[:repo] = i["payload"]["repo"] || i["repository"]["name"]
          ev[:object] = i["payload"]["object"] || ""
          begin
            ev[:followee] = i["payload"]["target"]["login"]
          rescue NoMethodError
            ev[:followee] = ""
          end

          if i["payload"]["object"].eql? "branch"
            ev["BranchEvent"] = true
          elsif i["payload"]["object"].eql? "tag"
            ev["TagEvent"] = true
          end
          ev[i["type"]] = true

          ret << ev
        end
        ret
      end

    end
  end
end

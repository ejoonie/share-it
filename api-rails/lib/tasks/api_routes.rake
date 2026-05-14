namespace :api do
  desc "Print mounted Grape API routes"
  task routes: :environment do
    routes = BaseAPI.routes

    if routes.empty?
      puts "No Grape routes found"
      next
    end

    puts "METHOD PATH                                     DESCRIPTION"
    puts "------ ---------------------------------------- -----------"

    routes
      .uniq { |route| [route.request_method, route.path] }
      .sort_by { |route| [route.path, route.request_method] }
      .each do |route|
        method = route.request_method.to_s.ljust(6)
        path = route.path.to_s.gsub("(.:format)", "")
        description = route.description.to_s

        puts format("%<method>s %<path>-40s %<description>s", method: method, path: path, description: description)
      end
  end
end


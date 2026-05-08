# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

require 'rspec/rails'

# Require support files
require_relative 'support/request_helpers'

RSpec.configure do |config|
  # If you're using fixtures, request specs will automatically include
  # ActiveRecord test helpers and transactional metadata
  config.use_transactional_fixtures = true

  # Load fixtures
  config.global_fixtures = :all
  config.fixture_paths = ["#{Rails.root}/spec/fixtures"]

  config.infer_spec_type_from_file_location!

  config.filter_rails_from_backtrace!
end


# Standard rails_helper.rb
# DO NOT MODIFY

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../spec/dummy/config/environment', __dir__)
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'

# Pre-load support files (use __dir__ so files in spec/support/ are found,
# not spec/dummy/spec/support/)
require 'rrx_dev/spec'
Dir[File.join(__dir__, 'support/**/*.rb')].sort.each { |f| require f }

# Solid queue tables are created inline via spec/support/solid_queue_schema.rb
# so we skip the standard migration check.

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end

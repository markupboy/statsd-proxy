ENV["BUNDLE_GEMFILE"] = File.expand_path("./Gemfile", File.dirname(__FILE__))
require "bundler/setup"

require "sinatra"
require "sinatra/config_file"
config_file 'config.yml'

require "statsd"
RACK_ENV ||=  settings.env || "development"
require "sinatra/reloader" if RACK_ENV == "development"

# Default app settings
set :environment, RACK_ENV.to_sym
set :logging, true
set :raise_errors, true

def build_client
  Statsd.new settings.statsd_host, settings.statsd_port
end

def statsd
  if settings.test?
    build_client
  else
    $statsd ||= build_client
  end
end

# we never allowed sample rate to be 0
def get_sample_rate(params)
  sample_rate = params["sample_rate"].to_f
  return nil if sample_rate == 0
  sample_rate
end

get '/increment' do
  sample_rate = get_sample_rate(params)
  args = [params["name"]]
  args << sample_rate if sample_rate
  statsd.increment *args
  [200, {'Content-Type' => 'image/gif'}, ""]
end

get '/decrement' do
  sample_rate = get_sample_rate(params)
  args = [params["name"]]
  args << sample_rate if sample_rate
  statsd.decrement *args
  [200, {'Content-Type' => 'image/gif'}, ""]
end

get '/timing' do
  sample_rate = get_sample_rate(params)
  args = [params["name"], params["value"].to_f]
  args << sample_rate if sample_rate
  statsd.timing *args
  [200, {'Content-Type' => 'image/gif'}, ""]
end

get '/gauge' do
  sample_rate = get_sample_rate(params)
  args = [params['name'], params['value'].to_f]
  args << sample_rate if sample_rate
  statsd.gauge *args
  [200, {'Content-Type' => 'image/gif'}, ""]
end

# encoding: utf-8
require File.join(File.dirname(__FILE__), 'application')

set :run, false
set :environment, :production

use Rack::Deflater


run Sinatra::Application

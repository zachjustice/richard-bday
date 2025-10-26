# require ::File.expand_path('../../config/environment',  __FILE__)
require_relative "../config/environment"
Rails.application.eager_load!

run ActionCable.server

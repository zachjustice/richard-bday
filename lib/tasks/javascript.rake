namespace :test do
  desc "Run JavaScript unit tests with Deno"
  task :js do
    system("deno test test/javascript/ --allow-read") || abort("JS tests failed")
  end
end

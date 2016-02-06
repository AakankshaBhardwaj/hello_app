namespace :mysql do

  desc "Create a database for this application."
  task :create_database => :environment do
    queue! %[echo "cd  #{current_path}; bundle exec rake db:create RAILS_ENV=#{rails_env}"]
  end
end
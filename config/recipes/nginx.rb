namespace :nginx do

  desc 'Install passenger with nginx module'
  task :install => :environment do
    queue! %[sudo -A apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7]
    queue! %[sudo -A apt-get install -y apt-transport-https ca-certificates]
    queue! %[sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main > /etc/apt/sources.list.d/passenger.list']
    # queue! %[sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger precise main > /etc/apt/sources.list.d/passenger.list']
    queue! %[sudo apt-get update]
    queue! %[sudo apt-get install -y nginx-extras passenger]
    queue! %[echo '-------------------------------------------------------->>>']
    queue %[echo "edit /etc/nginx/nginx.conf and uncomment passenger_root and passenger_ruby. For example, you may see this:"]
    queue %[echo "# passenger_root /some-filename/locations.ini;"]
    queue %[echo "# passenger_ruby /usr/bin/passenger_free_ruby;"]
    queue! %[echo '-------------------------------------------------------->>>']
  end

  desc "Setup nginx configuration for this application"
  task :setup => :environment do
    queue! %[sudo -A su -c "echo '#{erb(File.join(__dir__, 'templates', 'nginx_passenger.erb'))}' > /etc/nginx/sites-enabled/#{application}"]
    queue! %[sudo -A rm -f /etc/nginx/sites-enabled/default]
  end

  %w[start stop restart].each do |command|
    desc "#{command} nginx"
    task command.to_sym => :environment do
      queue! %[sudo -A service nginx #{command}]
    end
  end
end
require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rvm' # for rvm support. (http://rvm.io)
require 'yaml'
require 'io/console'

['base', 'nginx', 'mysql', 'check'].each do |pkg|
  require "#{File.join(__dir__, 'recipes', "#{pkg}")}"
end

set :application, 'kakaduheaderlabs'
set :user, set_user
set :deploy_to, "/home/#{user}/#{application}"


set :repository, "https://github.com/AakankshaBhardwaj/hello_app"
set :branch, set_branch

set :shared_paths, ['config/database.yml']
set :ruby_version, "#{File.readlines(File.join(__dir__, '..', '.ruby-version')).first.strip}"
set :gemset, "#{File.readlines(File.join(__dir__, '..', '.ruby-gemset')).first.strip}"

task :environment do
  set :rails_env, ENV['on'].to_sym unless ENV['on'].nil?
  require "#{File.join(__dir__, 'deploy', "#{rails_env}_configurations_files", "#{rails_env}.rb")}"
  invoke :"rvm:use[#{ruby_version}@#{gemset}]"
end

task :setup => :environment do
  invoke :set_sudo_password
  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/log"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/log"]

  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/config"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/config"]

  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/tmp/pids"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/tmp/pids"]

  queue! %[mkdir -p  "#{deploy_to}/#{shared_path}/photofy"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/photofy"]

  queue! %[touch "#{deploy_to}/#{shared_path}/config/database.yml"]
  invoke :setup_prerequesties
  invoke :setup_yml
  queue %[echo "-----> Be sure to edit 'shared/config/*.yml files'."]

end

task :setup_prerequesties => :environment do
  queue 'echo "-----> Installing development dependencies"'
  [
      'python-software-properties', 'libmysqlclient-dev', 'imagemagick', 'libmagickwand-dev', 'nodejs',
      'build-essential', 'zlib1g-dev', 'libssl-dev', 'libreadline-dev', 'libyaml-dev', 'libcurl4-openssl-dev', 'curl',
      'git-core', 'libreoffice', 'make', 'gcc', 'g++', 'pkg-config', 'libfuse-dev', 'libxml2-dev', 'zip', 'libtool',
      'xvfb', 'mysql-client', 'git', 'mime-support', 'automake', 'memcached'
  ].each do |package|
    puts "Installing #{package}"
    queue! %[sudo -A apt-get install -y #{package}]
  end

  queue 'echo "-----> Installing Ruby Version Manager"'
  queue! %[command curl -sSL https://rvm.io/mpapis.asc | gpg --import]
  queue! %[curl -sSL https://get.rvm.io | bash -s stable --ruby]

  queue! %[source "#{rvm_path}"]
  queue! %[rvm requirements]
  queue! %[rvm install "#{ruby_version}"]
  invoke :"rvm:use[#{ruby_version}@#{gemset}]"
  queue! %[gem install bundler]

  queue! %[mkdir "#{deploy_to}"]
  queue! %[chown -R "#{user}" "#{deploy_to}"]
  # #setup nginx
  invoke :'nginx:install'
  # #setup nginx
  invoke :'nginx:setup'
  invoke :'nginx:restart'

end
# SSL certificates path
# set :ssl_enabled, true
# set :cert_path, "#{deploy_tong}/current/ssl-certs/#{rails_env}/SSL.crt"
# set :cert_key_path, "#{deploy_to}/current/ssl-certs/#{rails_env}/Kakadu.key"
#

task :setup_yml => :environment do
  Dir[File.join(__dir__, '*.example.yml')].each do |_path|
    queue! %[echo "#{erb _path}" > "#{File.join(deploy_to, 'shared/config', File.basename(_path, '.example.yml') +'.yml')}"]
  end
end


desc "Deploys the current version to the server."
task :deploy => :environment do
  to :before_hook do
    # Put things to run locally before ssh
  end
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'check:revision'
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'mysql:create_database'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'
  end
  invoke :restart
end


task :set_sudo_password => :environment do
  queue! "echo '#{erb(File.join(__dir__, 'deploy', "#{rails_env}_configurations_files", 'sudo_password.erb'))}' > /home/#{user}/SudoPass.sh"
  queue! "chmod +x /home/#{user}/SudoPass.sh"
  queue! "export SUDO_ASKPASS=/home/#{user}/SudoPass.sh"
end


desc 'Restart passenger server'
task :restart => :environment do
  invoke :set_sudo_password
  queue! %[sudo -A service nginx restart]
  queue 'echo "-----> Start Passenger"'
  queue! %[mkdir -p #{File.join(current_path, 'tmp')}]
  queue! %[touch #{File.join(current_path, 'tmp', 'restart.txt')}]
end
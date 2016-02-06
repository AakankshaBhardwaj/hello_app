def set_user
  default_user = 'deploy'
  STDOUT.puts "username (Default is #{default_user}) :"
  user = STDIN.gets.strip
  user = default_user if user.empty?
  user
end

def set_branch
  default_branch = `git rev-parse --abbrev-ref HEAD`.chomp
  STDOUT.puts "Branch to deploy (Default:- #{default_branch}) :"
  branch = STDIN.gets.strip
  branch = default_branch if branch.empty?
  branch
end
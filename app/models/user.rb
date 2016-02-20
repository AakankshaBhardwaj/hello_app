class User < ActiveRecord::Base
  require 'benchmark'
  def say_hello
    n = 50000
    Benchmark.bmbm do |x|
      x.report('name'){
      User.last
      }
    end
  end
end

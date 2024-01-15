class TestController < ApplicationController
  def index(_check = true)
    puts 'welcome'
    a = 10
    eval('a * 2')
  end
end

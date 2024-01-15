class TestController < ApplicationController
  def index
    puts 'welcome'
    a = 10
    eval('a * 2')
  end
end

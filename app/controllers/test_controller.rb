class TestController < ApplicationController
  def index
    puts 'nac'
    a = 10
    puts eval('a * 10')
  end
end

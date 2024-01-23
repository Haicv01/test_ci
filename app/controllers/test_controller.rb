class TestController < ApplicationController
  def index
    a = 100
    puts eval('a * 100')
  end
end

class TopController < ApplicationController
  def index
    PageDailyView.record!("index")
  end
end

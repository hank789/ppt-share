# coding: utf-8
class Cpanel::HomeController < Cpanel::ApplicationController
  def index
    @recent_slides = Slide.recent.limit(25)
  end
end

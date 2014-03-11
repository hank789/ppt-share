# coding: utf-8
class Cpanel::HomeController < Cpanel::ApplicationController
  def index
    @recent_slides = Slide.recent.limit(5)
  end
end

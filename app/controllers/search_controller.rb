# coding: utf-8
class SearchController < ApplicationController
  def index
    keywords = params[:q] || ""
    keywords.gsub!("#", "%23")
    redirect_to "https://www.google.com.hk/#hl=zh-CN&q=site:saashow.com+#{keywords}"
  end
end

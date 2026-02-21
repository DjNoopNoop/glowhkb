class GlobalController < ApplicationController
  def map
    @publications = Publication.where.not(latitude: nil, longitude: nil).select(:id, :title, :year, :journal, :url, :latitude, :longitude)
  end

  def search
  end
end
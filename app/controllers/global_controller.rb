class GlobalController < ApplicationController
  def map
    @publications = Publication.joins(:geographic_location)
                               .where.not(geographic_locations: { latitude: nil, longitude: nil })
                               .select(
                                 'publications.id',
                                 'publications.title',
                                 'publications.year',
                                 'publications.journal',
                                 'publications.url',
                                 'geographic_locations.latitude AS latitude',
                                 'geographic_locations.longitude AS longitude'
                               )
  end

  def search
  end
end
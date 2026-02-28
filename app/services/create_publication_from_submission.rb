class CreatePublicationFromSubmission
  def initialize(submission)
    @submission = submission
  end

  # Creates a Publication from an approved Submission.
  # Returns the created Publication or the existing one if already created.
  def call
    return nil unless @submission&.approved?

    existing_publication || create_publication
  end

  private

  def existing_publication
    Publication.find_by(submission_id: @submission.id)
  end

  def create_publication
    Publication.transaction do
      pub = Publication.create!(
        title: @submission.title,
        authors: @submission.authors,
        journal: @submission.journal,
        year: @submission.year,
        doi: @submission.doi,
        url: @submission.url,
        submission: @submission,
        geographic_location: @submission.geographic_location,
        user: @submission.user
      )

      pub.air_pollutant_ids = @submission.air_pollutant_ids
      pub.weather_parameter_ids = @submission.weather_parameter_ids
      pub.medical_condition_ids = @submission.medical_condition_ids
      pub.statistical_method_ids = @submission.statistical_method_ids

      pub.save! unless pub.persisted?
      pub
    end
  end
end

require_relative 'base'

module RrxJobs::Configuration
  class Metrics < Base
    attribute :namespace, :string

    validates_format_of :namespace,
                        allow_nil: true,
                        with: /\A[A-Z][A-Za-z]+(?:\/[A-Z][A-Za-z]+){0,5}\Z/

    def enabled?
      namespace.present?
    end
  end
end

# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  include StrippedFields

  self.abstract_class = true

  # Use Rails native multi-DB with read replicas when configured.
  # When USE_DB_WORKER_REPLICAS is set, database.yml defines a primary_replica
  # connection that is used for the :reading role.
  if ENV["USE_DB_WORKER_REPLICAS"] == "true"
    connects_to database: {
      writing: :primary,
      reading: :primary_replica
    }
  end
end

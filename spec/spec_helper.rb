require "simplecov"

SimpleCov.start "rails" do
  enable_coverage :branch
  minimum_coverage ENV.fetch("MINIMUM_COVERAGE", 80).to_i

  skip "/config/"
  skip "/spec/"
  # Clases base generadas por Rails, sin logica propia todavia.
  # Quitar cada skip en cuanto el archivo tenga codigo real.
  skip "app/controllers/application_controller.rb"
  skip "app/jobs/application_job.rb"
  skip "app/mailers/application_mailer.rb"
  skip "app/models/application_record.rb"

  group "Services", "app/services"
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "tmp/rspec_examples.txt"
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed
end

# El API habla camelCase con el frontend (TypeScript) y snake_case adentro
# (Ruby). La traduccion vive aca y en los serializers, en un solo lugar.
module CamelCasePayload
  extend ActiveSupport::Concern

  private

  def underscored_params
    ActionController::Parameters.new(
      params.to_unsafe_h.deep_transform_keys { |key| key.to_s.underscore }
    )
  end

  def camelized_errors(record)
    record.errors.messages.transform_keys { |attribute| attribute.to_s.camelize(:lower) }
  end
end

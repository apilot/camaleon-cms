module CamaleonCms
  module Admin
    module CustomFieldsConcern
      extend ActiveSupport::Concern

      private

      # Only permit field_options that match registered custom field slugs
      def cama_permitted_field_options(object_class)
        return {} unless params[:field_options].present?

        allowed_keys = cama_custom_field_allowed_slugs(object_class)
        return {} if allowed_keys.blank?

        field_options = params.require(:field_options)
        field_options.permit(field_options.keys.select { |k| k.to_s =~ /\A\d+\z/ }.index_with do
          allowed_keys.index_with { [:id, :group_number, { values: {} }] }
        end).to_h
      end

      def cama_custom_field_allowed_slugs(object_class)
        CamaleonCms::CustomField.where(
          parent_id: CamaleonCms::CustomField.where(object_class: object_class).select(:id),
          object_class: '_fields'
        ).pluck(:slug).uniq
      end
    end
  end
end

module CamaleonCms
  module Admin
    module ApplicationHelper
      # include CamaleonCms::Admin::ApiHelper
      include CamaleonCms::Admin::MenusHelper
      include CamaleonCms::Admin::PostTypeHelper
      include CamaleonCms::Admin::CategoryHelper
      include CamaleonCms::Admin::CustomFieldsHelper

      # render pagination for current items
      # items is a will pagination object
      # sample: <%= cama_do_pagination(@posts) %>
      def cama_do_pagination(items, *will_paginate_options)
        will_paginate_options = will_paginate_options.extract_options!
        custom_class = will_paginate_options.delete(:panel_class)
        content_tag(:div, class: "row #{custom_class} pagination_panel cama_ajax_request") do
          concat(content_tag(:div, class: 'col-md-10') do
            will_paginate(items, will_paginate_options)
          rescue StandardError
            ''
          end)
          concat(content_tag(:div, class: 'col-md-2 text-right total-items') do
            content_tag(:strong) do
              total = begin
                items.total_entries
              rescue StandardError
                items.count
              end
              "#{I18n.t('camaleon_cms.admin.table.total', default: 'Total')}: #{total}"
            end
          end)
        end
      end

      # return the locale for frontend translations initialized in admin controller
      # used by models like posts, categories, ..., sample: my_post.the_url
      # fix for https://github.com/owen2345/camaleon-cms/issues/233#issuecomment-215385432
      def cama_get_i18n_frontend
        @cama_i18n_frontend
      end

      # print code with auto copy
      def cama_shortcode_print(code)
        content_tag(:code, code, class: 'cama_shortcode_code')
      end
    end
  end
end

module CamaleonCms
  module CommentHelper
    # return common data to save a new comment
    # user_id, author, aothor_email, author_ip, approved, :agent
    def cama_comments_get_common_data
      comment_data = {}
      comment_data[:user_id] = cama_current_user.id
      comment_data[:author] = cama_current_user.the_name
      comment_data[:author_email] = cama_current_user.email
      comment_data[:author_IP] = request.remote_ip.to_s
      comment_data[:approved] = 'approved'
      comment_data[:agent] = request.user_agent.force_encoding('ISO-8859-1').encode('UTF-8')
      comment_data
    end

    # render as html content all comments recursively
    # comments: collection of comments
    def cama_comments_render_html(comments)
      comments.decorate.map do |comment|
        author = comment.the_author
        labels = { 'approved' => 'success', 'pending' => 'warning', 'spam' => 'danger' }
        content_tag(:div, class: 'media') do
          concat(content_tag(:div, class: 'media-left') do
            link_to(author.the_admin_profile_url) do
              image_tag(author.the_avatar, class: 'media-object', style: 'width: 64px; height: 64px;')
            end
          end)
          concat(content_tag(:div, class: 'media-body') do
            concat(content_tag(:h4, class: 'media-heading') do
              concat(author.the_name)
              concat(' ')
              concat(content_tag(:small, comment.the_created_at))
              concat(' ')
              concat(content_tag(:span, t("camaleon_cms.admin.comments.message.#{comment.approved}"), class: "label label-#{labels[comment.approved]} pull-right"))
            end)
            concat(content_tag(:div, sanitize(comment.content), class: 'comment_content'))
            concat(content_tag(:div, class: 'comment_actions') do
              concat(content_tag(:div, class: 'pull-left') do
                concat(
                  link_to(
                    cama_admin_post_comment_answer_path(@post.id, comment.id),
                    data: { comment_id: comment.id },
                    title: t('camaleon_cms.admin.comments.tooltip.reply_comment'),
                    class: 'btn btn-info reply btn-xs ajax_modal'
                  ) { content_tag(:span, '', class: 'fa fa-mail-reply') }
                )
                concat(' ')
                concat(
                  link_to(
                    { action: :destroy, id: comment.id },
                    method: :delete,
                    data: { confirm: t('camaleon_cms.admin.message.delete') },
                    class: 'btn btn-danger btn-xs cama_ajax_request',
                    title: t('camaleon_cms.admin.comments.tooltip.delete_comment')
                  ) { content_tag(:i, '', class: 'fa fa-trash-o') }
                )
              end)
              concat(content_tag(:div, class: 'pull-right') do
                concat(
                  link_to(
                    url_for({ action: :toggle_status, comment_id: comment.id, s: 'a' }),
                    title: t('camaleon_cms.admin.comments.tooltip.approved_comment'),
                    class: "#{comment.approved == 'approved' ? 'hidden' : ''} btn btn-success approve btn-xs cama_ajax_request"
                  ) { content_tag(:span, '', class: 'fa fa-thumbs-o-up') }
                )
                concat(' ')
                concat(
                  link_to(
                    url_for({ action: :toggle_status, comment_id: comment.id, s: 'p' }),
                    title: t('camaleon_cms.admin.comments.tooltip.comment_pending'),
                    class: "#{comment.approved == 'pending' ? 'hidden' : ''} btn btn-primary pending btn-xs cama_ajax_request"
                  ) { content_tag(:span, '', class: 'fa fa-warning') }
                )
                concat(' ')
                concat(
                  link_to(
                    url_for({ action: :toggle_status, comment_id: comment.id, s: 's' }),
                    title: t('camaleon_cms.admin.comments.tooltip.comment_spam'),
                    class: "#{comment.approved == 'spam' ? 'hidden' : ''} btn btn-danger spam btn-xs cama_ajax_request"
                  ) { content_tag(:span, '', class: 'fa fa-bug') }
                )
              end)
            end)
            concat(content_tag(:hr))
            concat(content_tag(:div, '', class: 'clearfix'))
            concat(cama_comments_render_html(comment.children))
          end)
        end
      end.join('').html_safe
    end
  end
end

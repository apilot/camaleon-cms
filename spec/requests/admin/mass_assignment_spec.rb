# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin Mass Assignment Protection', type: :request do
  let(:site) { create(:site) }
  let(:admin) { create(:user, site: site, role: 'admin') }
  let(:post_type) { create(:post_type, site: site) }

  before do
    # Disable all hooks to avoid side effects and NoMethodErrors in some plugins/hooks
    allow_any_instance_of(CamaleonCms::HooksHelper).to receive(:hooks_run).and_return(true)
    
    # Ensure admin has permission for everything relevant
    admin.set_meta("_manager_#{site.id}", { 'widgets' => 1, 'categories' => 1, 'settings' => 1 })
    
    sign_in_as(admin, site: site)
  end

  describe 'Categories' do
    it 'blocks unauthorized attributes on create' do
      cat_name = "New Category #{Time.now.to_i}"
      post "/admin/post_type/#{post_type.id}/categories", params: {
        category: { name: cat_name, taxonomy: 'malicious_taxonomy' }
      }

      category = CamaleonCms::Category.find_by(name: cat_name)
      expect(category).to be_present
      expect(category.taxonomy).to eq('category')
    end

    it 'blocks unauthorized attributes on update' do
      category = post_type.categories.create!(name: 'Original Name', site_id: site.id)
      patch "/admin/post_type/#{post_type.id}/categories/#{category.id}", params: {
        category: { name: 'Updated Name', term_group: 999 } # term_group is aliased to site_id
      }

      category.reload
      expect(category.name).to eq('Updated Name')
      expect(category.term_group.to_i).to eq(site.id)
    end
  end

  describe 'Widgets' do
    it 'blocks unauthorized attributes on main widget create' do
      controller = CamaleonCms::Admin::Appearances::Widgets::MainController.new
      # Mock current_site
      allow(controller).to receive(:current_site).and_return(site)
      
      params = ActionController::Parameters.new(
        widget_main: {
          name: 'Test Widget',
          slug: 'test-widget',
          parent_id: 999, # unauthorized
          user_id: 999 # unauthorized
        }
      )
      allow(controller).to receive(:params).and_return(params)
      
      # We want to check what is passed to current_site.widgets.new
      expect(site.widgets).to receive(:new).with(hash_including(name: 'Test Widget')) do |permitted_params|
        expect(permitted_params[:parent_id]).to be_nil
        expect(permitted_params[:user_id]).to be_nil
        CamaleonCms::Widget::Main.new(permitted_params) # return a dummy object
      end
      
      # Trigger create (it will fail later because of redirect_to but we care about the params)
      begin
        controller.send(:create)
      rescue
        nil
      end
    end

    it 'blocks unauthorized attributes on sidebar create' do
      controller = CamaleonCms::Admin::Appearances::Widgets::SidebarController.new
      allow(controller).to receive(:current_site).and_return(site)
      
      params = ActionController::Parameters.new(
        widget_sidebar: {
          name: 'Test Sidebar',
          slug: 'test-sidebar',
          parent_id: 999
        }
      )
      allow(controller).to receive(:params).and_return(params)
      
      expect(site.sidebars).to receive(:new).with(hash_including(name: 'Test Sidebar')) do |permitted_params|
        expect(permitted_params[:parent_id]).to be_nil
        CamaleonCms::Widget::Sidebar.new(permitted_params)
      end
      
      begin
        controller.send(:create)
      rescue
        nil
      end
    end

    it 'blocks unauthorized attributes on widget assignment update' do
      sidebar = CamaleonCms::Widget::Sidebar.create!(name: 'Sidebar', parent_id: site.id, taxonomy: 'sidebar')
      widget = CamaleonCms::Widget::Main.create!(name: 'Widget', parent_id: site.id, taxonomy: 'widget')
      assigned = sidebar.assigned.create!({ title: 'Default', widget_id: widget.id })
      
      patch "/admin/appearances/widgets/sidebar/#{sidebar.id}/assign/#{assigned.id}", params: {
        assign: { title: 'Updated Title', visibility: 999 } # visibility is aliased to widget_id
      }
      
      assigned.reload
      expect(assigned.title).to eq('Updated Title')
      # visibility should NOT be 999
      expect(assigned.visibility.to_i).to eq(widget.id)
    end
  end
end

# encoding: UTF-8
require 'redmine'
require 'base64'

module RedmineDrawio

    class ViewLayoutsBaseHtmlHeadHook < Redmine::Hook::ViewListener

        # This method will add the necessary CSS and JS scripts to the page header.
        # The scripts are loaded before the 'jstoolbar-textile.min.js' is loaded so
        # the toolbar cannot be patched.
        # A second step is required: the textile_helper.rb inserts a small Javascript
        # fragment after the jstoolbar-textile is loaded, which pathes the jsToolBar
        # object.
        def view_layouts_base_html_head(context={})
            return '' unless editable?(context)
            
            header = <<-EOF
                <script type=\"text/javascript\">//<![CDATA[
                    var Drawio = {
                      settings: {
                        redmineUrl: '#{redmine_url}',
                        hashCode  : '#{Base64.encode64(User.current.api_key).reverse!.gsub(/\n/, '\\\\\n')}',
                        drawioUrl : '#{Setting.plugin_redmine_drawio['drawio_service_url']}',
                        DMSF      : #{dmsf_enabled? context},
                        isEasyRedmine: #{easyredmine?}
                      }
                    };
                //]]></script>
            EOF
            
            header << stylesheet_link_tag("drawioEditor.css"  , :plugin => "redmine_drawio", :media => "screen")
            header << javascript_include_tag("drawioEditor.js", :plugin => "redmine_drawio")
            header << javascript_include_tag("lang/drawio_jstoolbar-en.js", :plugin => "redmine_drawio")
            header << javascript_include_tag("lang/drawio_jstoolbar-#{current_language.to_s.downcase}.js", :plugin => "redmine_drawio")
            header << javascript_include_tag("drawio_jstoolbar.js", :plugin => "redmine_drawio") unless ckeditor_enabled?
            header << javascript_include_tag("http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS_SVG")  if Setting.plugin_redmine_drawio['drawio_mathjax']
            header
        end
        
        private
        
        def editable?(context)
            return false unless context[:controller]
            return true  if context[:controller].is_a?(WikiController) && User.current.allowed_to?(:edit_wiki_pages, context[:project])
            return false unless context[:controller].is_a?(IssuesController)

            if context[:issue].nil?
                return true if context[:journal].nil?
                context[:journal].editable_by?(User.current)
            else
                context[:issue].editable?(User.current)
            end
        end
        
        # Returns the context path of Redmine installation (usually '/' or '/redmine/').
        def redmine_url
            rootUrl = ActionController::Base.relative_url_root

            return rootUrl+'/' if rootUrl != nil

            return '/'
        end
        
        def dmsf_enabled?(context)
            return false unless Redmine::Plugin.installed? :redmine_dmsf
            return false unless context[:project] && context[:project].module_enabled?('dmsf')
            true
        end
        
        def ckeditor_enabled?
            Setting.text_formatting == "CKEditor"
        end
        
        def easyredmine?
            Redmine::Plugin.installed?(:easy_redmine)
        end

    end
    
end

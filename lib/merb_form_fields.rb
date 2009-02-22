# make sure we're running inside Merb
if defined?(Merb::Plugins)
  # Merb gives you a Merb::Plugins.config hash...feel free to put your stuff in your piece of it
  Merb::Plugins.config[:merb_form_fields] = {
    :field_tag => :div,
    :field_class => "field",
    :field_error_class => "error",
    :add_field_type_class? => true,
    
    :error_message_tag => :em,
    :error_message_class => "error",

    :skipped_field_types => [:hidden_field, :check_box, :radio_button]
  }
  
  Merb::BootLoader.before_app_loads do
    Merb::Controller.send(:include, MerbFormFields::ViewHelpers)
  end  
end

# load classes
require 'merb_form_fields/form_field_builder'
require 'merb_form_fields/view_helpers'

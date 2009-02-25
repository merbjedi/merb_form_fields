module MerbFormFields 
  class FormFieldBuilder < Merb::Helpers::Form::Builder::ResourcefulForm

    # --------------------------------------------------------
    # override the following methods to customize FieldBuilder
    # --------------------------------------------------------

    # This tag wraps inner error messages
    def error_message_tag
      Merb::Plugins.config[:merb_form_fields][:error_message_tag] || :em
    end

    # This tag wraps the field
    def field_tag
      Merb::Plugins.config[:merb_form_fields][:field_tag] || :div
    end

    # This is the default field class
    def field_class
      Merb::Plugins.config[:merb_form_fields][:field_class] || "field"
    end
    
    # This tag wraps the note
    def note_tag
      Merb::Plugins.config[:merb_form_fields][:note_tag] || :span
    end

    # This is the default note class
    def note_class
      Merb::Plugins.config[:merb_form_fields][:note_class] || "note"
    end
    

    # whether or not to add the field_type class
    def add_field_type_class?
      if Merb::Plugins.config[:merb_form_fields][:add_field_type_class?].nil?
        true
      else
        Merb::Plugins.config[:merb_form_fields][:add_field_type_class?]
      end
    end

    # These field types are skipped (not wrapped in a field div)
    def skipped_field_types
      Merb::Plugins.config[:merb_form_fields][:skipped_field_types] || [:hidden_field, :check_box, :radio_button]
    end

    # ---------------------------------------------
    # wrapper method implementation
    # ---------------------------------------------
    def field_wrapper(field_type, attrs = {})
      field_options = attrs.delete(:field) || {}
      note = attrs.delete(:note)
      error_override = attrs.delete(:error)

      # build inner field html (using the passed in block) 
      inner_html = yield if block_given?

      # skip certain field types 
      # :fields => {:force => true} will force the field to show
      # :fields => {:skip => true} will prevent the field from showing
      if (field_options[:force] != true and skipped_field_types.include?(field_type)) or field_options[:skip] == true
        return inner_html
      end

      # build class string
      css_class = field_options[:class] || "#{field_class} #{field_type if add_field_type_class?}"
      if error_class = field_error_class(@obj, attrs[:method])
        css_class << " #{error_class}"
      end

      # build note
      note_html = tag(note_tag, note, :class => note_class) unless note.blank?

      # build field
      tag field_tag,
          "#{inner_html}#{field_error_message(@obj, attrs[:method], error_override)}#{note_html}",
          field_options.merge(:class => css_class)
    end

    # returns the class added to the field element if there was an error
    def field_error_class(obj, method)
      if obj && method && !obj.errors.on(method.to_sym).blank?
        Merb::Plugins.config[:merb_form_fields][:field_error_class] || "error"
      else
        ""
      end
    end

    # displays the inner error message element
    def field_error_message(obj, method, error_override = nil)
      if obj && method
        error = obj.errors.on(method.to_sym)
        unless error.blank?
          return "\n<#{error_message_tag} class='#{Merb::Plugins.config[:merb_form_fields][:error_message_class] || "error"}'>#{error_override || error}</#{error_message_tag}>"
        end
      end
    end

    # we'll make our own errors, thank you very much
    def error_messages_for(obj, error_class, build_li, header, before)
      obj ||= @obj
      return "" unless obj.respond_to?(:errors)

      sequel = !obj.errors.respond_to?(:each)
      errors = sequel ? obj.errors.full_messages : obj.errors

      return "" if errors.empty?

      header_message = header % [errors.size, errors.size == 1 ? "" : "s"]
      markup = %Q{<div class='#{error_class}'>#{header_message}<ul>}
      errors.each {|err| markup << (build_li % (sequel ? err : err.join(" ")))}
      markup << %Q{</ul></div>}
    end

    # ------------------------------------------------------------------------
    # methods below are hacks to support merb field wrapping
    # there needs to be a hook added to merb-core that allows this more easily
    # ------------------------------------------------------------------------
    %w(text password hidden file).each do |kind|
      self.class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def bound_#{kind}_field(method, attrs = {})
          name = control_name(method)
          field_wrapper(:#{kind}_field, attrs.merge(:method => method)) do
            super
          end
        end
      RUBY
    end

    def bound_check_box(method, attrs = {})
      name = control_name(method)
      field_wrapper(:check_box, attrs.merge(:method => method)) do
        super
      end
    end

    def bound_radio_button(method, attrs = {})
      name = control_name(method)
      field_wrapper(:radio_button, attrs.merge(:method => method)) do
        super
      end
    end

    def bound_radio_group(method, arr)
      val = control_value(method)

      field_wrapper(:radio_group, attrs.merge(:method => method, :arr => arr)) do
        super
      end
    end

    def bound_select(method, attrs = {})
      name = control_name(method)
      field_wrapper(:select, attrs.merge(:method => method)) do
        super
      end
    end

    def bound_text_area(method, attrs = {})
      name = "#{@name}[#{method}]"
      field_wrapper(:text_area, attrs.merge(:method => method)) do
        super
      end
    end
    
  end
end
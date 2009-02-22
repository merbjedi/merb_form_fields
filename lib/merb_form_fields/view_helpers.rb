module MerbFormFields 
  module ViewHelpers
    def form_with_fields_for(name, attrs = {}, &blk)
      with_form_context(name, MerbFormFields::FormFieldBuilder) do
        current_form_context.form(attrs, &blk)
      end
    end
  end
end
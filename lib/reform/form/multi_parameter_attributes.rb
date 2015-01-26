Reform::Form.class_eval do
  module MultiParameterAttributes
    def self.included(base)
      base.send(:register_feature, self)
    end

    class DateTimeParamsFilter
      def call(params)
        date_attributes = {}

        params.each do |attribute, value|
          if value.is_a?(Hash)
            call(value) # TODO: #validate should only handle local form params.
          elsif matches = attribute.match(/^(\w+)\(.i\)$/)
            date_attribute = matches[1]
            date_attributes[date_attribute] = params_to_date(
              params.delete("#{date_attribute}(1i)"),
              params.delete("#{date_attribute}(2i)"),
              params.delete("#{date_attribute}(3i)"),
              params.delete("#{date_attribute}(4i)"),
              params.delete("#{date_attribute}(5i)")
            )
          end
        end
        params.merge!(date_attributes)
      end

    private
      def params_to_date(year, month, day, hour, minute)
        return nil if [year, month, day].any?(&:blank?)

        if hour.blank? && minute.blank?
          Date.new(year.to_i, month.to_i, day.to_i) # TODO: test fails.
        else
          args = [year, month, day, hour, minute].map(&:to_i)
          Time.zone ? Time.zone.local(*args) :
            Time.new(*args)
        end
      end
    end

    def validate(params)
      # TODO: make it cleaner to hook into essential reform steps.
      # TODO: test with nested.
      params = DateTimeParamsFilter.new.call(params.dup) if params.is_a?(Hash) # this currently works for hash, only.

      super
    end


    # module ClassMethods
    #   def representer_class # TODO: check out how we can utilise Config#features.
    #     super.class_eval do
    #       extend BuildDefinition
    #       self
    #     end
    #   end
    # end


    # module BuildDefinition
    #   def build_definition(name, options, &block)
    #     return super unless options[:multi_params]

    #     options[:parse_filter] << DateParamsFilter.new
    #     super
    #   end
    # end
  end
end

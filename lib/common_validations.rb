# = Common Validations
#
# The validations listed here are the common ways of testing some
# input later passed to bencoder
#
# Validations are built as chainable calls.
# The object that is passed through is an errors hash.
# In case of invalid input every validation call modifies the errors
# hash by adding the element with the key of +attribute+ and value as a
# message
module CommonValidations

  def validate_presence_of(attribute, object, errors) #:nodoc:#
    if object && object.is_a?(Hash) && object[attribute] &&
      (object[attribute].is_a?(Fixnum) || !object[attribute].empty?)
      # good
    else
      errors[attribute] = 'is missing'
    end
  end

  def validate_uniqueness_of(attribute, object, errors) #:nodoc:#
    if object && object.is_a?(Hash) && object[attribute]
      uniq_values_count = object[attribute].uniq.size rescue 0
      if uniq_values_count != object[attribute].size
        errors[attribute] = 'should have unique values'
      end
    end
  end

  # == Validate URL
  #
  # Validates the format of url. URL should match URI.regexp
  # to be considered valid
  def validate_url_of(attribute, object, errors)
    if object && object.is_a?(Hash)
      return unless object[attribute]

      if object[attribute] =~ URI.regexp
        # good
      else
        errors[attribute] = 'is not a valid url'
      end
    end
  end

  # == Validate URLs array
  #
  # Validates the format of every URL inside the array
  # URL should match URI.regexp to be considered valid
  def validate_urls_array_of(attribute, object, errors)
    if object && object.is_a?(Hash) && object[attribute] &&
      object[attribute].is_a?(Array)

        object[attribute].each do |url_in_array|
          if url_in_array =~ URI.regexp
            # good
          else
            errors[attribute] = 'is not a valid array of urls'
            break
          end
        end
    end
  end
end
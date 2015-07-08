# Allow exception handlers to add information
# to an exception for upstream
class Exception
  def additional_information
    @additional_information ||= {}
  end
end

# frozen_string_literal: true

module NoticesHelper
  # @deprecated Remove it later
  def notice_atom_summary(notice)
    render "notices/atom_entry", notice: notice
  end
end

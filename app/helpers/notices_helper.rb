# frozen_string_literal: true

module NoticesHelper
  def notice_atom_summary(notice)
    render "notices/atom_entry", notice: notice
  end
end

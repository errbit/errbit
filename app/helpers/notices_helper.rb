# encoding: utf-8
module NoticesHelper
  def notice_atom_summary(notice)
    render "notices/atom_entry", notice: notice
  end
end

# encoding: utf-8
module NoticesHelper
  def notice_atom_summary notice
    render :partial => "notices/atom_entry.html.haml", :locals => {:notice => notice}
  end
end
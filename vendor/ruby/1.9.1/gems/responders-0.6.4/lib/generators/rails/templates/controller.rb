class <%= controller_class_name %>Controller < ApplicationController
<% unless options[:singleton] -%>
  # GET /<%= table_name %>
  # GET /<%= table_name %>.xml
  def index
    @<%= table_name %> = <%= orm_class.all(class_name) %>
    respond_with(@<%= table_name %>)
  end
<% end -%>

  # GET /<%= table_name %>/1
  # GET /<%= table_name %>/1.xml
  def show
    @<%= file_name %> = <%= orm_class.find(class_name, "params[:id]") %>
    respond_with(@<%= file_name %>)
  end

  # GET /<%= table_name %>/new
  # GET /<%= table_name %>/new.xml
  def new
    @<%= file_name %> = <%= orm_class.build(class_name) %>
    respond_with(@<%= file_name %>)
  end

  # GET /<%= table_name %>/1/edit
  def edit
    @<%= file_name %> = <%= orm_class.find(class_name, "params[:id]") %>
  end

  # POST /<%= table_name %>
  # POST /<%= table_name %>.xml
  def create
    @<%= file_name %> = <%= orm_class.build(class_name, "params[:#{file_name}]") %>
    <%= "flash[:notice] = '#{class_name} was successfully created.' if " if flash? %>@<%= orm_instance.save %>
    respond_with(@<%= file_name %>)
  end

  # PUT /<%= table_name %>/1
  # PUT /<%= table_name %>/1.xml
  def update
    @<%= file_name %> = <%= orm_class.find(class_name, "params[:id]") %>
    <%= "flash[:notice] = '#{class_name} was successfully updated.' if " if flash? %>@<%= orm_instance.update_attributes("params[:#{file_name}]") %>
    respond_with(@<%= file_name %>)
  end

  # DELETE /<%= table_name %>/1
  # DELETE /<%= table_name %>/1.xml
  def destroy
    @<%= file_name %> = <%= orm_class.find(class_name, "params[:id]") %>
    @<%= orm_instance.destroy %>
    respond_with(@<%= file_name %>)
  end
end

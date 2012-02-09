# -*- encoding: binary -*-

require 'digest/sha1'
class FooController < ApplicationController
  def index
    render :text => "FOO\n"
  end

  def xcookie
    cookies["foo"] = "cookie #$$"
    render :text => ""
  end

  def xnotice
    flash[:notice] = "session #$$"
    render :text => ""
  end

  def xpost
    if request.post?
      digest = Digest::SHA1.new
      out = "params: #{params.inspect}\n"
      if file = params[:file]
        loop do
          buf = file.read(4096) or break
          digest.update(buf)
        end
        out << "sha1: #{digest.to_s}\n"
      end
      headers['content-type'] = 'text/plain'
      render :text => out
    else
      render :status => 403, :text => "need post\n"
    end
  end
end

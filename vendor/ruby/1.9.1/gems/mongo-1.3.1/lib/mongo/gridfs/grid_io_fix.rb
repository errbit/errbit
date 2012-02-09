# encoding: UTF-8

# --
# Copyright (C) 2008-2011 10gen Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ++

module Mongo
  class GridIO

    # This fixes a comparson issue in JRuby 1.9
    def get_md5
      md5_command            = BSON::OrderedHash.new
      md5_command['filemd5'] = @files_id
      md5_command['root']    = @fs_name
      @server_md5 = @files.db.command(md5_command)['md5']
      if @safe
        @client_md5 = @local_md5.hexdigest
        if @local_md5.to_s != @server_md5.to_s
          raise GridMD5Failure, "File on server failed MD5 check"
        end
      else
        @server_md5
      end
    end
  end
end

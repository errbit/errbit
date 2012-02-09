# encoding: utf-8
module Mongoid #:nodoc:
  module Collections #:nodoc:
    module Operations #:nodoc:

      # Constant definining all the read operations available for a
      # Mongo:Collection. This is used in delegation.
      READ = [
        :[],
        :db,
        :count,
        :distinct,
        :find,
        :find_one,
        :group,
        :index_information,
        :map_reduce,
        :mapreduce,
        :stats,
        :options
      ]

      # Constant definining all the write operations available for a
      # Mongo:Collection. This is used in delegation.
      WRITE = [
        :<<,
        :create_index,
        :drop,
        :drop_index,
        :drop_indexes,
        :find_and_modify,
        :insert,
        :remove,
        :rename,
        :save,
        :update
      ]

      # Convenience constant for getting back all collection operations.
      ALL = (READ + WRITE)
      PROXIED = ALL - [ :find, :find_one, :map_reduce, :mapreduce, :update ]
    end
  end
end

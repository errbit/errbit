class RefingerprintErrs < ActiveRecord::Migration
  def up
    require "refingerprint_errs"
    RefingerprintErrs.execute
  end

  def down
  end
end

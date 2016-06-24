class SiteConfig
  CONFIG_SOURCE_SITE = 'site'.freeze
  CONFIG_SOURCE_APP = 'app'.freeze

  include Mongoid::Document
  include Mongoid::Timestamps

  after_save :denormalize

  embeds_one :notice_fingerprinter, autobuild: true
  validates_associated :notice_fingerprinter
  accepts_nested_attributes_for :notice_fingerprinter

  # Get the one and only SiteConfig document
  def self.document
    first || create
  end

  # Denormalize SiteConfig onto individual apps so that this record doesn't
  # need to be accessed when inserting new error notices
  def denormalize
    App.each do |app|
      f = app.notice_fingerprinter
      next if f.source && f.source != CONFIG_SOURCE_SITE

      app.update_attributes(
        notice_fingerprinter: notice_fingerprinter_attributes)
    end
  end

  def notice_fingerprinter_attributes
    notice_fingerprinter.attributes.tap do |attrs|
      attrs.delete('_id')
      attrs[:source] = :site
    end
  end
end

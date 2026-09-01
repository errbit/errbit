# frozen_string_literal: true

class HistoricalNoticeSanitizer
  DEFAULT_BATCH_SIZE = 500
  Result = Data.define(:scanned, :changed, :unchanged, :failed)

  def initialize(scope: Notice.all, batch_size: DEFAULT_BATCH_SIZE, limit: nil, dry_run: true, logger: Rails.logger)
    @scope = scope
    @batch_size = Integer(batch_size)
    @limit = limit && Integer(limit)
    @dry_run = dry_run
    @logger = logger

    raise ArgumentError, "batch size must be positive" unless @batch_size.positive?
    raise ArgumentError, "limit must be positive" if @limit && !@limit.positive?
  end

  def run
    counts = {scanned: 0, changed: 0, unchanged: 0, failed: 0}
    criteria = @scope.order_by(:_id.asc).batch_size(@batch_size)
    criteria = criteria.limit(@limit) if @limit

    criteria.each do |notice|
      counts[:scanned] += 1
      sanitized = notice.sanitized_attributes(privacy: true)

      if changed?(notice, sanitized)
        if @dry_run
          counts[:changed] += 1
        elsif update_notice(notice, sanitized)
          counts[:changed] += 1
        else
          counts[:failed] += 1
          @logger.error("Historical notice sanitization failed for #{notice.id}: notice no longer exists")
        end
      else
        counts[:unchanged] += 1
      end
    rescue => e
      counts[:failed] += 1
      @logger.error("Historical notice sanitization failed for #{notice.id}: #{e.class}")
    end

    Result.new(**counts)
  end

  private

  def changed?(notice, sanitized)
    sanitized.any? { |field, value| notice.attributes[field] != value }
  end

  def update_notice(notice, sanitized)
    # Use a direct collection update so the scrub does not alter timestamps or
    # trigger unrelated Notice callbacks.
    Notice.collection.find_one_and_update(
      {"_id" => notice.id},
      {"$set" => sanitized}
    ).present?
  end
end

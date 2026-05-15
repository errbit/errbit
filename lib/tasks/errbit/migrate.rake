# frozen_string_literal: true

namespace :errbit do
  namespace :migrate do
    desc "Migrate users from MongoDB to Errbit::User (SQL). Idempotent — re-runs update by bson_id."
    task users: :environment do
      stats = {created: 0, updated: 0, failed: 0}

      Errbit::User.transaction do
        Errbit::User.record_timestamps = false

        ::User.all.each do |mongo_user|
          bson_id = mongo_user._id.to_s

          ar_user = Errbit::User.find_or_initialize_by(bson_id: bson_id)
          existed = ar_user.persisted?

          ar_user.assign_attributes(
            email: mongo_user.email.to_s,
            encrypted_password: mongo_user.encrypted_password.to_s,
            reset_password_token: mongo_user.reset_password_token,
            reset_password_sent_at: mongo_user.reset_password_sent_at,
            remember_created_at: mongo_user.remember_created_at,
            sign_in_count: mongo_user.sign_in_count || 0,
            current_sign_in_at: mongo_user.current_sign_in_at,
            last_sign_in_at: mongo_user.last_sign_in_at,
            current_sign_in_ip: mongo_user.current_sign_in_ip,
            last_sign_in_ip: mongo_user.last_sign_in_ip,
            authentication_token: mongo_user.authentication_token,
            name: mongo_user.name,
            username: mongo_user.try(:username),
            admin: mongo_user.admin || false,
            per_page: mongo_user.per_page || Errbit::User::PER_PAGE,
            time_zone: mongo_user.time_zone || "UTC",
            github_login: mongo_user.github_login,
            github_oauth_token: mongo_user.github_oauth_token,
            google_uid: mongo_user.google_uid,
            created_at: mongo_user.created_at,
            updated_at: mongo_user.updated_at
          )

          if ar_user.save(validate: false)
            if existed
              stats[:updated] += 1
            else
              stats[:created] += 1
            end
          else
            stats[:failed] += 1
            warn "  failed bson_id=#{bson_id}: #{ar_user.errors.full_messages.join(", ")}"
          end
        rescue ActiveRecord::RecordNotUnique => e
          stats[:failed] += 1
          warn "  failed bson_id=#{bson_id}: #{e.message}"
        end
      ensure
        Errbit::User.record_timestamps = true
      end

      puts "=== Migrated users: #{stats[:created]} created, #{stats[:updated]} updated, #{stats[:failed]} failed."
    end
  end
end

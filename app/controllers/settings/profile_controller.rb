# frozen_string_literal: true

class Settings::ProfileController < Settings::BaseController
  before_action :authorize

  def show
    profile_presenter = ProfilePresenter.new(pundit_user:, seller: current_seller)

    render inertia: "Settings/Profile/Show", props: settings_presenter.profile_props.merge(
      profile_presenter.profile_settings_props(request:)
    )
  end

  def update
    return respond_error("You have to confirm your email address before you can do that.") unless current_seller.confirmed?

    blob_id_param_present = permitted_params.has_key?(:profile_picture_blob_id)
    profile_picture_blob_id = permitted_params[:profile_picture_blob_id]

    if profile_picture_blob_id.present?
      return respond_error("The logo is already removed. Please refresh the page and try again.") if ActiveStorage::Blob.find_signed(profile_picture_blob_id).nil?
    end

    begin
      ActiveRecord::Base.transaction do
        seller_profile = current_seller.seller_profile
        sections = current_seller.seller_profile_sections.on_profile
        if permitted_params[:tabs]
          tabs = permitted_params[:tabs].as_json
          tabs.each { |tab| (tab["sections"] ||= []).map! { ObfuscateIds.decrypt(_1) } }
          sections.each do |section|
            section.destroy! if tabs.none? { _1["sections"]&.include?(section.id) }
          end
          seller_profile.json_data["tabs"] = tabs
        end
        seller_profile.assign_attributes(permitted_params[:seller_profile]) if permitted_params[:seller_profile].present?
        seller_profile.save!

        # Avatar handling: stage the attachment change on `current_seller` and
        # explicitly save inside the transaction. ActiveStorage's `.attach` only
        # auto-saves when `record.persisted? && !record.changed?`, so if the
        # record is dirty (or if no `:user` params are present to trigger
        # `current_seller.update!`), the staged attachment_changes never get
        # persisted — and `set_avatar_changed` → `generate_subscribe_preview`
        # never fires. Driving the save explicitly here makes the callback
        # chain deterministic.
        avatar_change_pending = false
        if profile_picture_blob_id.present?
          begin
            current_seller.avatar.attach profile_picture_blob_id
            avatar_change_pending = true
          rescue ActiveRecord::RecordNotUnique
            current_seller.avatar.reload
          end
        elsif blob_id_param_present && current_seller.avatar.attached?
          current_seller.avatar.purge
          avatar_change_pending = true
        end

        if permitted_params[:user]
          current_seller.assign_attributes(permitted_params[:user])
        end

        if avatar_change_pending || permitted_params[:user] || current_seller.changed?
          current_seller.save!
        end

        current_seller.clear_products_cache if profile_picture_blob_id.present?
      end
      respond_success
    rescue ActiveRecord::RecordInvalid => e
      respond_error(e.record.errors.full_messages.to_sentence)
    end
  end

  private
    def authorize
      super(profile_policy)
    end

    def permitted_params
      params.permit(policy(profile_policy).permitted_attributes)
    end

    def profile_policy
      [:settings, :profile]
    end

    def respond_error(message)
      if request.inertia?
        redirect_to settings_profile_path, alert: message
      else
        render json: { success: false, error_message: message }
      end
    end

    def respond_success
      if request.inertia?
        redirect_to settings_profile_path, status: :see_other, notice: "Changes saved!"
      else
        render json: { success: true }
      end
    end
end

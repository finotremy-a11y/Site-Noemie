module Api
  module V1
    module Me
      class PreferencesController < BaseController
        before_action :authenticate_user!

        def show
          pref = current_user.preferences
          render json: {
            data: {
              language: "fr",
              notifications: {
                email_order: pref.notifications_email_order,
                email_quote: pref.notifications_email_quote,
                email_promotional: pref.notifications_email_promotional
              }
            }
          }
        end

        def update
          pref = current_user.preferences
          attrs = params.require(:preferences).permit(notifications: [ :email_order, :email_quote, :email_promotional ])

          # Flatten nested notifications
          pref_attrs = attrs.to_h.dup
          if attrs[:notifications].present?
            pref_attrs.delete(:notifications)
            attrs[:notifications].each do |key, value|
              pref_attrs["notifications_#{key}"] = value
            end
          end

          if pref.update(pref_attrs)
            render json: {
              data: {
                language: "fr",
                notifications: {
                  email_order: pref.notifications_email_order,
                  email_quote: pref.notifications_email_quote,
                  email_promotional: pref.notifications_email_promotional
                }
              }
            }
          else
            render_error(
              code: "validation_error",
              message: "Erreur de modification des préférences.",
              details: pref.errors.messages,
              status: :unprocessable_entity
            )
          end
        end
      end
    end
  end
end

module Api
  module V1
    module Me
      class AddressesController < BaseController
        before_action :authenticate_user!

        def index
          addresses = current_user.addresses.order(address_type: :asc, is_default: :desc)
          render json: {
            data: addresses.map { |addr| serialize_address(addr) }
          }
        end

        def create
          address = current_user.addresses.build(address_params)

          if address.save
            render json: { data: serialize_address(address) }, status: :created
          else
            render_error(
              code: "validation_error",
              message: "Erreur de création de l'adresse.",
              details: address.errors.messages,
              status: :unprocessable_entity
            )
          end
        end

        def show
          address = current_user.addresses.find(params[:id])
          render json: { data: serialize_address(address) }
        rescue ActiveRecord::RecordNotFound
          render_error(code: "not_found", message: "Adresse non trouvée", status: :not_found)
        end

        def update
          address = current_user.addresses.find(params[:id])

          if address.update(address_params)
            render json: { data: serialize_address(address) }
          else
            render_error(
              code: "validation_error",
              message: "Erreur de modification de l'adresse.",
              details: address.errors.messages,
              status: :unprocessable_entity
            )
          end
        rescue ActiveRecord::RecordNotFound
          render_error(code: "not_found", message: "Adresse non trouvée", status: :not_found)
        end

        def destroy
          address = current_user.addresses.find(params[:id])
          address.destroy!
          render json: { data: { message: "Adresse supprimée" } }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render_error(code: "not_found", message: "Adresse non trouvée", status: :not_found)
        end

        private

        def address_params
          params.require(:address).permit(:address_type, :full_name, :street, :city, :postal_code, :country, :phone, :notes, :is_default)
        end

        def serialize_address(address)
          {
            id: address.id,
            address_type: address.address_type,
            full_name: address.full_name,
            street: address.street,
            city: address.city,
            postal_code: address.postal_code,
            country: address.country,
            phone: address.phone,
            notes: address.notes,
            is_default: address.is_default,
            created_at: address.created_at
          }
        end
      end
    end
  end
end

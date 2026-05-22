class ContactsController < ApplicationController
  def new
    @contact = ContactRequest.new
  end

  def create
    @contact = ContactRequest.new(contact_params)

    if @contact.save
      Notifications::InquiryNotificationJob.perform_later(
        subject: "[N&L Cuisinent] Nouveau message de contact",
        lines: [
          "Nom: #{@contact.name}",
          "Email: #{@contact.email}",
          "Téléphone: #{@contact.phone}",
          "Sujet: #{@contact.subject}",
          "Message:",
          @contact.message
        ]
      )

      redirect_to root_path, notice: "Merci pour votre message! Nous vous répondrons bientôt."
    else
      flash.now[:alert] = @contact.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  private

  def contact_params
    params.require(:contact_request).permit(:name, :email, :phone, :subject, :message)
  end
end

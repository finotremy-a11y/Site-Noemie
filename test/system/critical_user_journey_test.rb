require "application_system_test_case"

class CriticalUserJourneyTest < ApplicationSystemTestCase
  test "visitor can navigate critical pages" do
    visit root_path
    assert_text "Des burgers qui changent tout"

    click_link "Voir la carte"
    assert_current_path catalog_path
    assert_text "Notre Carte"

    visit cart_path
    assert_text "Mon Panier"

    visit checkout_path
    assert(has_text?("Finaliser ma commande") || has_text?("Notre Carte"))

    visit contact_path
    assert_text "Contact"
  end
end

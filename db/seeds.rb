# Seeds de démo — idempotents (find_or_create_by!)
# Lancer avec: rails db:seed

seed_demo_users = !Rails.env.production? || ENV["SEED_DEMO_USERS"] == "true"

BusinessSetting.current

puts "Seeding categories..."

categories = [
  { name: "Burgers", description: "Nos burgers premium faits maison", position: 1 },
  { name: "Accompagnements", description: "Frites, salades et sauces", position: 2 },
  { name: "Boissons", description: "Softs, milkshakes et eaux", position: 3 },
  { name: "Desserts", description: "Douceurs pour finir en beauté", position: 4 },
  { name: "Menus", description: "Formules complètes", position: 5 },
  { name: "Événements", description: "Prestations traiteur et événementiel", position: 6 }
]

categories.each do |cat|
  category = Category.find_or_initialize_by(name: cat[:name])
  category.slug = cat[:name].parameterize
  category.position = cat[:position]
  category.active = true
  category.save!
end

puts "  #{Category.count} catégories"

puts "Seeding products..."

cat_burgers      = Category.find_by!(name: "Burgers")
cat_accomp       = Category.find_by!(name: "Accompagnements")
cat_boissons     = Category.find_by!(name: "Boissons")
cat_desserts     = Category.find_by!(name: "Desserts")
cat_menus        = Category.find_by!(name: "Menus")

products = [
  # Burgers
  { name: "Le Classique N&L", description: "Boeuf haché 180g, cheddar affiné, salade, tomate, oignons caramélisés, sauce maison", price_cents: 1390, category: cat_burgers },
  { name: "Le Smoky", description: "Boeuf haché 180g, bacon fumé, cheddar, sauce barbecue, pickles", price_cents: 1490, category: cat_burgers },
  { name: "Le Végé", description: "Steak de pois chiches, avocat, chèvre frais, roquette, sauce yaourt citron", price_cents: 1290, category: cat_burgers },
  { name: "Le Double Down", description: "Double steak boeuf 2×160g, double cheddar, sauce spéciale, oignons frits", price_cents: 1690, category: cat_burgers },
  { name: "Le Poulet Croustillant", description: "Escalope de poulet panée, coleslaw maison, cornichons, sauce honey mustard", price_cents: 1290, category: cat_burgers },
  # Accompagnements
  { name: "Frites Maison", description: "Pommes de terre fraîches coupées à la main, fleur de sel", price_cents: 390, category: cat_accomp },
  { name: "Onion Rings", description: "Rondelles d'oignon panées, sauce dip", price_cents: 450, category: cat_accomp },
  { name: "Salade Verte", description: "Mélange de saisons, tomates cerises, vinaigrette balsamique", price_cents: 350, category: cat_accomp },
  { name: "Sauce Maison", description: "Sauce signature N&L — recette secrète", price_cents: 100, category: cat_accomp },
  # Boissons
  { name: "Coca Cola", description: "33cl", price_cents: 290, category: cat_boissons },
  { name: "Milkshake Vanille", description: "Milkshake glacé à la vanille naturelle", price_cents: 490, category: cat_boissons },
  { name: "Milkshake Chocolat", description: "Milkshake glacé au cacao pur", price_cents: 490, category: cat_boissons },
  { name: "Eau Minérale", description: "50cl", price_cents: 190, category: cat_boissons },
  # Desserts
  { name: "Brownie Maison", description: "Brownie au chocolat noir, sauce caramel beurre salé", price_cents: 450, category: cat_desserts },
  { name: "Cookie Géant", description: "Cookie aux pépites de chocolat, servi chaud", price_cents: 390, category: cat_desserts },
  # Menus
  { name: "Menu Classique", description: "Burger au choix + Frites Maison + Boisson", price_cents: 1790, category: cat_menus },
  { name: "Menu Double", description: "Double burger + Frites + Boisson + Dessert", price_cents: 2290, category: cat_menus }
]

products.each do |p|
  Product.find_or_create_by!(name: p[:name]) do |prod|
    prod.description    = p[:description]
    prod.price_cents    = p[:price_cents]
    prod.category       = p[:category]
    prod.active         = true
    prod.stock_quantity = 99
  end
end

puts "  #{Product.count} produits"

if seed_demo_users
  puts "Seeding admin user..."

  admin = User.find_or_initialize_by(email: "nl.cuisinent@gmail.com")
  if admin.new_record?
    admin.password         = "Admin1234!"
    admin.password_confirmation = "Admin1234!"
    admin.role             = "admin"
    admin.first_name       = "Admin"
    admin.last_name        = "N&L"
    admin.save!
    puts "  Admin créé: nl.cuisinent@gmail.com / Admin1234!"
  else
    puts "  Admin déjà existant"
  end

  puts "Seeding demo customer..."

  customer = User.find_or_initialize_by(email: "demo@nletl.fr")
  if customer.new_record?
    customer.password      = "Demo1234!"
    customer.password_confirmation = "Demo1234!"
    customer.role          = "customer"
    customer.first_name    = "Marie"
    customer.last_name     = "Dupont"
    customer.phone         = "0634936801"
    customer.save!
    puts "  Client demo créé: demo@nletl.fr / Demo1234!"
  else
    puts "  Client demo déjà existant"
  end
else
  puts "Skipping demo users in production (set SEED_DEMO_USERS=true to enable)"
end

puts "\nDone! #{Category.count} catégories, #{Product.count} produits, #{User.count} utilisateurs."

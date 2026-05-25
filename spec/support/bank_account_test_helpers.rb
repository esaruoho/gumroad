# frozen_string_literal: true

module BankAccountTestHelpers
  DEFAULT_BANK_ACCOUNT_ATTRIBUTES = {
    "AchAccount" => { account_number: "1112121234", account_number_last_four: "1234", account_holder_full_name: "Gumbot Gumstein I", bank_number: "110000000", account_type: "checking" },
    "CanadianBankAccount" => { account_number: "1234567", account_number_last_four: "4567", account_holder_full_name: "Gumbot Gumstein I", bank_number: "123", branch_code: "12345" },
    "AustralianBankAccount" => { account_number: "1234567", account_number_last_four: "4567", account_holder_full_name: "Gumbot Gumstein I", bank_number: "062111" },
    "UkBankAccount" => { account_number: "1234567", account_number_last_four: "4567", account_holder_full_name: "Gumbot Gumstein I", bank_number: "06-21-11" },
    "EuropeanBankAccount" => { account_number: "DE89370400440532013000", account_number_last_four: "3000", account_holder_full_name: "Stripe DE Account", account_type: "checking" },
    "HongKongBankAccount" => { account_number: "000123456", account_number_last_four: "3456", account_holder_full_name: "Gumbot Gumstein I", branch_code: "000", bank_number: "110" },
    "NewZealandBankAccount" => { account_number: "1100000000000010", account_number_last_four: "0010", account_holder_full_name: "Gumbot Gumstein I" },
    "SingaporeanBankAccount" => { account_number: "000123456", account_number_last_four: "3456", account_holder_full_name: "Gumbot Gumstein I", branch_code: "000", bank_number: "1100" },
    "SwissBankAccount" => { account_number: "CH9300762011623852957", account_number_last_four: "3000", account_holder_full_name: "Gumbot Gumstein I" },
    "PolandBankAccount" => { account_number: "PL61109010140000071219812874", account_number_last_four: "2874", account_holder_full_name: "Gumbot Gumstein I" },
    "CzechRepublicBankAccount" => { account_number: "CZ6508000000192000145399", account_number_last_four: "3000", account_holder_full_name: "Gumbot Gumstein I" },
    "ThailandBankAccount" => { account_number: "000123456789", account_number_last_four: "6789", account_holder_full_name: "Gumbot Gumstein I", bank_number: "999" },
    "BulgariaBankAccount" => { account_number: "BG80BNBG96611020345678", account_number_last_four: "2874", account_holder_full_name: "Gumbot Gumstein I" },
    "DenmarkBankAccount" => { account_number: "DK5000400440116243", account_number_last_four: "2874", account_holder_full_name: "Gumbot Gumstein I" },
    "HungaryBankAccount" => { account_number: "HU42117730161111101800000000", account_number_last_four: "2874", account_holder_full_name: "Gumbot Gumstein I" },
    "KoreaBankAccount" => { account_number: "000123456789", account_number_last_four: "6789", account_holder_full_name: "Gumbot Gumstein I", bank_number: "SGSEKRSLXXX" },
    "UaeBankAccount" => { account_number: "AE070331234567890123456", account_number_last_four: "3456", account_holder_full_name: "Gumbot Gumstein I" },
    "AntiguaAndBarbudaBankAccount" => { account_number: "000123456789", account_number_last_four: "6789", account_holder_full_name: "Antigua and Barbuda Creator I", bank_number: "AAAAAGAGXYZ" },
    "TanzaniaBankAccount" => { account_number: "0000123456789", account_number_last_four: "6789", account_holder_full_name: "Tanzanian Creator I", bank_number: "AAAATZTXXXX" },
    "NamibiaBankAccount" => { account_number: "000123456789", account_number_last_four: "6789", account_holder_full_name: "Namibia Creator I", bank_number: "AAAANANXXYZ" },
    "IsraelBankAccount" => { account_number: "IL620108000000099999999", account_number_last_four: "9999", account_holder_full_name: "Gumbot Gumstein I" },
    "TrinidadAndTobagoBankAccount" => { account_number: "00567890123456789", account_number_last_four: "6789", account_holder_full_name: "Gumbot Gumstein I", branch_code: "00001", bank_number: "999" },
    "PhilippinesBankAccount" => { account_number: "01567890123456789", account_number_last_four: "I123", account_holder_full_name: "Gumbot Gumstein I", bank_number: "BCDEFGHI123" },
    "RomaniaBankAccount" => { account_number: "RO49AAAA1B31007593840000", account_number_last_four: "0000", account_holder_full_name: "Gumbot Gumstein I" },
    "SwedenBankAccount" => { account_number: "SE3550000000054910000003", account_number_last_four: "0003", account_holder_full_name: "Gumbot Gumstein I" },
    "MexicoBankAccount" => { account_number: "000000001234567897", account_number_last_four: "7897", account_holder_full_name: "Gumbot Gumstein I" },
    "ArgentinaBankAccount" => { account_number: "0110000600000000000000", account_number_last_four: "0000", account_holder_full_name: "Gumbot Gumstein I" },
    "LiechtensteinBankAccount" => { account_number: "LI0508800636123378777", account_number_last_four: "8777", account_holder_full_name: "Liechtenstein Creator" },
    "PeruBankAccount" => { account_number: "99934500012345670024", account_number_last_four: "0024", account_holder_full_name: "Gumbot Gumstein I" },
    "NorwayBankAccount" => { account_number: "NO9386011117947", account_number_last_four: "7947", account_holder_full_name: "Norwegian Creator" },
    "IndianBankAccount" => { account_number: "000123456789", account_number_last_four: "6789", account_holder_full_name: "Gumbot Gumstein I", bank_number: "HDFC0004051" },
    "VietnamBankAccount" => { account_number: "000123456789", account_number_last_four: "6789", account_holder_full_name: "Gumbot Gumstein I", bank_number: "01101100" },
    "TaiwanBankAccount" => { account_number: "0001234567", account_number_last_four: "4567", account_holder_full_name: "Gumbot Gumstein I", bank_number: "AAAATWTXXXX" },
    "BosniaAndHerzegovinaBankAccount" => { account_number: "BA095520001234567812", account_number_last_four: "7812", account_holder_full_name: "Bosnia and Herzegovina Creator I", bank_number: "AAAABABAXXX" },
    "IndonesiaBankAccount" => { account_number: "000123456789", account_number_last_four: "6789", account_holder_full_name: "Gumbot Gumstein I", bank_number: "000" },
    "CostaRicaBankAccount" => { account_number: "CR04010212367856709123", account_number_last_four: "9123", account_holder_full_name: "Gumbot Gumstein I" },
    "BotswanaBankAccount" => { account_number: "000123456789", account_number_last_four: "6789", account_holder_full_name: "Botswana Creator", bank_number: "AAAABWBWXXX" },
    "ChileBankAccount" => { account_number: "000123456789", account_number_last_four: "6789", account_holder_full_name: "Gumbot Gumstein I", bank_number: "999" },
    "PakistanBankAccount" => { account_number: "PK36SCBL0000001123456702", account_number_last_four: "6702", account_holder_full_name: "Gumbot Gumstein I", bank_number: "AAAAPKKAXXX" },
    "TurkeyBankAccount" => { account_number: "TR320010009999901234567890", account_number_last_four: "7890", account_holder_full_name: "Gumbot Gumstein I", bank_number: "ADABTRIS" },
    "MoroccoBankAccount" => { account_number: "MA64011519000001205000534921", account_number_last_four: "4921", account_holder_full_name: "Gumbot Gumstein I", bank_number: "AAAAMAMAXXX" },
    "AzerbaijanBankAccount" => { account_number: "AZ77ADJE12345678901234567890", account_number_last_four: "7890", account_holder_full_name: "Azerbaijani Creator I", bank_number: "123456", branch_code: "123456" },
    "AlbaniaBankAccount" => { account_number: "AL35202111090000000001234567", account_number_last_four: "4567", account_holder_full_name: "Albanian Creator I", bank_number: "AAAAALTXXXX" },
    "BahrainBankAccount" => { account_number: "BH29BMAG1299123456BH00", account_number_last_four: "BH00", account_holder_full_name: "Bahrainian Creator I", bank_number: "AAAABHBMXYZ" },
    "JordanBankAccount" => { account_number: "JO32ABCJ0010123456789012345678", account_number_last_four: "5678", account_holder_full_name: "Jordanian Creator I", bank_number: "AAAAJOJOXXX" },
    "EthiopiaBankAccount" => { account_number: "0000000012345", account_number_last_four: "2345", account_holder_full_name: "Ethiopia Creator", bank_number: "AAAAETETXXX" },
    "BruneiBankAccount" => { account_number: "0000123456789", account_number_last_four: "6789", account_holder_full_name: "Brunei Creator", bank_number: "AAAABNBBXXX" },
    "GuyanaBankAccount" => { account_number: "000123456789", account_number_last_four: "6789", account_holder_full_name: "Guyana Creator", bank_number: "AAAAGYGGXYZ", branch_code: "12345678" },
    "GuatemalaBankAccount" => { account_number: "GT20AGRO00000000001234567890", account_number_last_four: "7890", account_holder_full_name: "Guatemala Creator", bank_number: "AAAAGTGCXYZ" },
    "NigeriaBankAccount" => { account_number: "1111111112", account_number_last_four: "1112", account_holder_full_name: "Nigerian Creator I", bank_number: "AAAANGLAXXX" },
    "SerbiaBankAccount" => { account_number: "RS35105008123123123173", account_number_last_four: "3173", account_holder_full_name: "Gumbot Gumstein I", bank_number: "TESTSERBXXX" },
    "SouthAfricaBankAccount" => { account_number: "000001234", account_number_last_four: "0054", account_holder_full_name: "Gumbot Gumstein I", bank_number: "FIRNZAJJ" },
    "KenyaBankAccount" => { account_number: "000123456789", account_number_last_four: "6789", account_holder_full_name: "Gumbot Gumstein I", bank_number: "BARCKENXMDR" },
    "RwandaBankAccount" => { account_number: "000123456789", account_number_last_four: "6789", account_holder_full_name: "Rwandan Creator", bank_number: "AAAARWRWXXX" },
    "EgyptBankAccount" => { account_number: "EG800002000156789012345180002", account_number_last_four: "1111", account_holder_full_name: "Gumbot Gumstein I", bank_number: "NBEGEGCX331" },
    "ColombiaBankAccount" => { account_number: "000123456789", account_number_last_four: "6789", account_holder_full_name: "Gumbot Gumstein I", bank_number: "060", account_type: "savings" },
    "SaudiArabiaBankAccount" => { account_number: "SA4420000001234567891234", account_number_last_four: "1234", account_holder_full_name: "Gumbot Gumstein I", bank_number: "RIBLSARIXXX" },
    "JapanBankAccount" => { account_number: "0001234", account_number_last_four: "1234", account_holder_full_name: "Japanese Creator", bank_number: "1100", branch_code: "000" },
    "KazakhstanBankAccount" => { account_number: "KZ221251234567890123", account_number_last_four: "0123", account_holder_full_name: "Kaz creator", bank_number: "AAAAKZKZXXX" },
    "EcuadorBankAccount" => { account_number: "000123456789", account_number_last_four: "6789", account_holder_full_name: "Ecuadorian Creator", bank_number: "AAAAECE1XXX" },
    "MalaysiaBankAccount" => { account_number: "000123456000", account_number_last_four: "6000", account_holder_full_name: "Malaysian Creator I", bank_number: "HBMBMYKL" },
    "GibraltarBankAccount" => { account_number: "00012345", account_number_last_four: "2345", account_holder_full_name: "Gumbot Gumstein I", bank_number: "10-88-00" },
    "UruguayBankAccount" => { account_number: "000123456789", account_number_last_four: "6789", account_holder_full_name: "John Doe", bank_number: "999" },
    "MauritiusBankAccount" => { account_number: "MU17BOMM0101101030300200000MUR", account_number_last_four: "0MUR", account_holder_full_name: "John Doe", bank_number: "AAAAMUMUXYZ" },
    "AngolaBankAccount" => { account_number: "AO06004400006729503010102", account_number_last_four: "0102", account_holder_full_name: "Angola Creator", bank_number: "AAAAAOAOXXX" },
    "NigerBankAccount" => { account_number: "NE58NE0380100100130305000268", account_number_last_four: "0268", account_holder_full_name: "Niger Creator" },
    "SanMarinoBankAccount" => { account_number: "SM86U0322509800000000270100", account_number_last_four: "0100", account_holder_full_name: "San Marino Creator", bank_number: "AAAASMSMXXX" },
    "JamaicaBankAccount" => { account_number: "000123456789", account_number_last_four: "6789", account_holder_full_name: "John Doe", bank_number: "111", branch_code: "00000" },
    "BangladeshBankAccount" => { account_number: "0000123456789", account_number_last_four: "6789", account_holder_full_name: "Bangladesh Creator", bank_number: "110000000" },
    "BhutanBankAccount" => { account_number: "0000123456789", account_number_last_four: "6789", account_holder_full_name: "Bhutan Creator", bank_number: "AAAABTBTXXX" },
    "LaosBankAccount" => { account_number: "000123456789", account_number_last_four: "6789", account_holder_full_name: "Laos Creator", bank_number: "AAAALALAXXX" },
    "MozambiqueBankAccount" => { account_number: "001234567890123456789", account_number_last_four: "6789", account_holder_full_name: "Mozambique Creator", bank_number: "AAAAMZMXXXX" },
    "OmanBankAccount" => { account_number: "000123456789", account_number_last_four: "6789", account_holder_full_name: "Omani Creator", bank_number: "AAAAOMOMXXX" },
    "DominicanRepublicBankAccount" => { account_number: "000123456789", account_number_last_four: "6789", account_holder_full_name: "Chuck Bartowski", bank_number: "999" },
    "UzbekistanBankAccount" => { account_number: "99934500012345670024", account_number_last_four: "0024", account_holder_full_name: "Chuck Bartowski", bank_number: "AAAAUZUZXXX", branch_code: "00000" },
    "BoliviaBankAccount" => { account_number: "000123456789", account_number_last_four: "6789", account_holder_full_name: "Chuck Bartowski", bank_number: "040" },
    "TunisiaBankAccount" => { account_number: "TN5904018104004942712345", account_number_last_four: "2345", account_holder_full_name: "Gumbot Gumstein I" },
    "MoldovaBankAccount" => { account_number: "MD07AG123456789012345678", account_number_last_four: "5678", account_holder_full_name: "Moldova Creator", bank_number: "AAAAMDMDXXX" },
    "NorthMacedoniaBankAccount" => { account_number: "MK49250120000058907", account_number_last_four: "8907", account_holder_full_name: "Gumbot Gumstein I", bank_number: "AAAAMK2XXXX" },
    "PanamaBankAccount" => { account_number: "000123456789", account_number_last_four: "6789", account_holder_full_name: "Chuck Bartowski", bank_number: "AAAAPAPAXXX" },
    "ElSalvadorBankAccount" => { account_number: "1234567890", account_number_last_four: "7890", account_holder_full_name: "Salvadorian Creator", bank_number: "AAAASVS1XXX" },
    "MadagascarBankAccount" => { account_number: "MG4800005000011234567890123", account_number_last_four: "0123", account_holder_full_name: "Gumbot Gumstein I", bank_number: "AAAAMGMGXXX" },
    "ParaguayBankAccount" => { account_number: "0567890123456789", account_number_last_four: "6789", account_holder_full_name: "Paraguayan Creator", bank_number: "0" },
    "GhanaBankAccount" => { account_number: "000123456789", account_number_last_four: "6789", account_holder_full_name: "Ghanaian Creator", bank_number: "022112" },
    "ArmeniaBankAccount" => { account_number: "00001234567", account_number_last_four: "4567", account_holder_full_name: "Armenia creator", bank_number: "AAAAAMNNXXX" },
    "SriLankaBankAccount" => { account_number: "0000012345", account_number_last_four: "2345", account_holder_full_name: "Sri Lankan Creator", bank_number: "AAAALKLXXXX", branch_code: "7010999" },
    "KuwaitBankAccount" => { account_number: "KW81CBKU0000000000001234560101", account_number_last_four: "0101", account_holder_full_name: "Kuwaiti Creator", bank_number: "AAAAKWKWXYZ" },
    "IcelandBankAccount" => { account_number: "IS140159260076545510730339", account_number_last_four: "0339", account_holder_full_name: "Gumbot Gumstein I" },
    "QatarBankAccount" => { account_number: "QA87CITI123456789012345678901", account_number_last_four: "8901", account_holder_full_name: "Gumbot Gumstein I", bank_number: "AAAAQAQAXXX" },
    "BahamasBankAccount" => { account_number: "0001234", account_number_last_four: "1234", account_holder_full_name: "Gumbot Gumstein I", bank_number: "AAAABSNSXXX" },
    "SaintLuciaBankAccount" => { account_number: "000123456789", account_number_last_four: "6789", account_holder_full_name: "Saint Lucia Creator", bank_number: "AAAALCLCXYZ" },
    "SenegalBankAccount" => { account_number: "SN08SN0100152000048500003035", account_number_last_four: "3035", account_holder_full_name: "Gumbot Gumstein I" },
    "CambodiaBankAccount" => { account_number: "000123456789", account_number_last_four: "6789", account_holder_full_name: "Cambodian Creator", bank_number: "AAAAKHKHXXX" },
    "MongoliaBankAccount" => { account_number: "000123456789", account_number_last_four: "6789", account_holder_full_name: "Mongolia Creator", bank_number: "AAAAMNUBXXX" },
    "GabonBankAccount" => { account_number: "00001234567890123456789", account_number_last_four: "6789", account_holder_full_name: "Gumbot Gumstein I", bank_number: "AAAAGAGAXXX" },
    "MonacoBankAccount" => { account_number: "MC5810096180790123456789085", account_number_last_four: "9085", account_holder_full_name: "Gumbot Gumstein I" },
    "AlgeriaBankAccount" => { account_number: "00001234567890123456", account_number_last_four: "3456", account_holder_full_name: "Gumbot Gumstein I", bank_number: "AAAADZDZXXX" },
    "MacaoBankAccount" => { account_number: "0000000001234567897", account_number_last_four: "7897", account_holder_full_name: "Macao Creator", bank_number: "AAAAMOMXXXX" },
    "BeninBankAccount" => { account_number: "BJ66BJ0610100100144390000769", account_number_last_four: "0769", account_holder_full_name: "Benin Creator" },
    "CoteDIvoireBankAccount" => { account_number: "CI93CI0080111301134291200589", account_number_last_four: "0589", account_holder_full_name: "Cote d'Ivoire Creator" },
  }.freeze

  module_function

  def create_bank_account(bank_account_type, user:, **attributes)
    bank_account_class = bank_account_type.is_a?(Class) ? bank_account_type : bank_account_type.to_s.constantize
    return create_card_bank_account(user:, **attributes) if bank_account_class == CardBankAccount

    bank_account_class.create!(bank_account_attributes_for(bank_account_class).merge(attributes).merge(user:))
  end

  def bank_account_attributes_for(bank_account_class)
    DEFAULT_BANK_ACCOUNT_ATTRIBUTES.fetch(bank_account_class.name)
  end

  def create_card_bank_account(user:, **attributes)
    credit_card = attributes.delete(:credit_card) { create_debit_credit_card }
    CardBankAccount.create!(attributes.merge(user:, credit_card:))
  end

  def create_debit_credit_card
    CreditCard.create!(
      card_type: CardType::VISA,
      expiry_month: 12,
      expiry_year: Time.current.year + 1,
      stripe_customer_id: "cus_bank_account_test",
      visual: "**** **** **** 4242",
      stripe_fingerprint: "fp_bank_account_test",
      card_country: Compliance::Countries::USA.alpha2,
      charge_processor_id: StripeChargeProcessor.charge_processor_id,
      funding_type: ChargeableFundingType::DEBIT,
      processor_payment_method_id: "pm_bank_account_test"
    )
  end
end

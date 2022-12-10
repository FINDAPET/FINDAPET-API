//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 13.11.2022.
//

import Foundation
import Vapor

enum PetBreed: String, Content, CaseIterable {
    case Abyssinian, Anatoli, Asian, Bengal, Burmese, Ceylon, Chartreux, Chausie, Kanaani, Korat, Lykoy, Minskin, Nebelung, Ocicat, Persian, Peterbald, Ragdoll, Russian, Savannah, Serengeti, Siamese, Singapura, Snowshoe, Sokoke, Somali, Sphynx, Thai, Toybob, Toyger, York, Bolognese, Chihuahua, Dalmatin, Maltese, Norrbottenspitz, Stabijhoun, Xoloitzcuintle
    case Bombay = "Bombay(Asian)"
    case Burmilla = "Burmilla(Asian)"
    case Classicat = "Classicat(Ocicat blotched)"
    case Colourpoint = "Colourpoint(Himalayan)"
    case Cymric = "Cymric(Manx LH)"
    case Havana = "Havana(Havana Brown)"
    case Mandalay = "Mandalay(Burmese including caramel and tabby)"
    case Manx = "Manx(Manx SH)"
    case Tiffanie = "Tiffanie(Tiffany)"
    case AmericanBobtailSH = "American Bobtail SH"
    case AmericanBobtailLH = "American Bobtail LH"
    case AmericanCurlSH = "American Curl SH"
    case AmericanCurlLH = "American Curl LH"
    case AmericanShorthair = "American Shorthair"
    case AmericanWirehair = "American Wirehair"
    case AphroditesGiantSH = "Aphrodite's Giant SH"
    case AphroditesGiantLH = "Aphrodite's Giant LH"
    case ArabianMau = "Arabian Mau"
    case AustralianMist = "Australian Mist"
    case BrazilianShorthair = "Brazilian Shorthair"
    case BritishShorthair = "British Shorthair"
    case BritishLonghair = "British Longhair"
    case BurmillaLH = "Burmilla LH"
    case CelticShorthair = "Celtic Shorthair(European SH)"
    case ChineseLiHau = "Chinese Li Hau"
    case ColourpointShorthair = "Colourpoint Shorthair(Siamese: all other colours than the 4 basic colours)"
    case CornishRex = "Cornish Rex"
    case DevonRex = "Devon Rex"
    case DeutschLanghaar = "Deutsch Langhaar"
    case DonSphynx = "DonSphynx(Donskoy)"
    case EgyptianMau = "Egyptian Mau"
    case ExoticShorthair = "Exotic Shorthair(Exotic)"
    case ForeignWhiteSH = "Foreign White SH(Siamese white, Oriental SH white)"
    case ForeignWhiteLH = "Foreign White LH(Balinese white, Oriental LH white)"
    case GermanRex = "German Rex"
    case HouseholdPet = "Household pet(Domestic cat)"
    case HighlandFold = "Highland Fold(Scottish Fold LH)"
    case HighlandStraight = "Highland Straight(Scottish Straight LH)"
    case HighlanderSH = "Highlander SH"
    case HighlanderLH = "Highlander LH"
    case JapaneseBobtailSH = "Japanese Bobtail SH"
    case JapaneseBobtailLH = "Japanese Bobtail LH"
    case KarelianBobtailSH = "Karelian Bobtail SH"
    case KarelianBobtailLH = "Karelian Bobtail LH"
    case KurilianBobtailSH = "Kurilian Bobtail SH"
    case KurilianBobtailLH = "Kurilian Bobtail LH"
    case LaPermSH = "LaPerm SH"
    case LaPermLH = "LaPerm LH"
    case MaineCoon = "Maine Coon"
    case MekongBobtail = "Mekong Bobtail"
    case MunchkinSH = "Munchkin SH"
    case MunchkinLH = "Munchkin LH"
    case NevaMasquerade = "Neva Masquerade(Siberian Colourpoint)"
    case NorwegianForest = "Norwegian Forest"
    case OjosAzulesSH = "Ojos Azules SH"
    case OjosAzulesLH = "Ojos Azules LH"
    case OrientalSemiLonghair = "Oriental (Semi-) Longhair(Javanese Mandarin)"
    case OrientalShorthair = "Oriental Shorthair(Oriental)"
    case OriginalLonghair = "Original Longhair"
    case PixiebobSH = "Pixiebob SH"
    case PixiebobLH = "Pixiebob LH"
    case RussianBlue = "Russian Blue"
    case SacredBirman = "Sacred Birman(Birman)"
    case ScottishFold = "Scottish Fold"
    case ScottishStraight = "Scottish Straight(Scottish SH, Scottish)"
    case SelkirkRexSH = "Selkirk Rex SH"
    case SelkirkRexLH = "Selkirk Rex LH"
    case SiberianCat = "Siberian cat(Siberian)"
    case TonkaneseSH = "Tonkanese SH"
    case TonkaneseLH = "Tonkanese LH"
    case TurkishAngora = "Turkish Angora"
    case TurkishVan = "Turkish Van"
    case TurkishVankedisi = "Turkish Vankedisi(Turkish Van white)"
    case UralRexSH = "Ural Rex SH"
    case UralRexLH = "Ural Rex LH"
    case BerneseMountainDog = "Bernese Mountain Dog"
    case CannanDog = "Cannan Dog"
    case CimaronUruguayo = "Cimaron Uruguayo"
    case RomanianBucovinaShepherd = "Romanian Bucovina Shepherd"
    case DanishSwedishFarmdog = "Danish-Swedish Farmdog"
    case DogoArgentino = "Dogo Argentino"
    case DogueDeBordeaux = "Dogue De Bordeaux"
    case FilaBrasiliero = "Fila Brasiliero"
    case DutchShepherdDog = "Dutch Shepherd Dog"
    case CroatianShepherdDog = "Croatian Shepherd Dog"
    case IstrianWireHairedHound = "Istrian Wire-Haired Hound"
    case IstrianShortHairedHound = "Istrian Short-Haired Hound"
    case KangalShepherdDog = "Kangal Shepherd Dog"
    case KarelianBearDog = "Karelian Bear Dog"
    case LapponianHerder = "Lapponian Herder"
    case PeruvianHairlessDog = "Peruvian Hairless Dog"
    case PosavatzHound = "Posavatz Hound"
    case RhodesianRidgeback = "Rhodesian Ridgeback"
    case FinnishHound = "Finnish Hound"
    case FinnishLapponianDog = "Finnish Lapponian Dog"
    case FinnishSpitz = "Finnish Spitz"
    case SwedishLapphund = "Swedish Lapphund"
    case BrazilianTerrier = "Brazilian Terrier"
    case SwedishVallhund = "Swedish Vallhund"
    case FrisianWaterDog = "Frisian Water Dog"
    case other = "Other"
}

extends HBoxContainer

var flag_de = preload("res://systems/localization/Keeper_de.png")
var flag_dk = preload("res://systems/localization/Keeper_dk.png")
var flag_en = preload("res://systems/localization/Keeper_us.png")
var flag_ja = preload("res://systems/localization/Keeper_jp.png")
var flag_zh = preload("res://systems/localization/Keeper_zh_CN.png")
var flag_es = preload("res://systems/localization/Keeper_es.png")
var flag_es_LAT = preload("res://systems/localization/Keeper_es_LAT.png")
var flag_fr = preload("res://systems/localization/keeper_fr.png")
var flag_fi = preload("res://systems/localization/Keeper_fi_FI.png")
var flag_it = preload("res://systems/localization/keeper_it.png")
var flag_ko = preload("res://systems/localization/keeper_ko.png")
var flag_nl = preload("res://systems/localization/Keeper_nl_NL.png")
var flag_no = preload("res://systems/localization/Keeper_no_NO.png")
var flag_pl = preload("res://systems/localization/keeper_pl.png")
var flag_pt_BR = preload("res://systems/localization/keeper_pt_BR.png")
var flag_pt_PT = preload("res://systems/localization/Keeper_pt_PT.png")
var flag_ro = preload("res://systems/localization/Keeper_ro.png")
var flag_ru = preload("res://systems/localization/Keeper_ru.png")
var flag_sv = preload("res://systems/localization/Keeper_sv.png")
var flag_th = preload("res://systems/localization/Keeper_th.png")
var flag_tr = preload("res://systems/localization/Keeper_tr.png")
var flag_vi = preload("res://systems/localization/Keeper_vi.png")
var flag_fo_FO = preload("res://systems/localization/Keeper_fo_FO.png")
var flag_bg = preload("res://systems/localization/Keeper_bg.png")
var flag_zh_TW = preload("res://systems/localization/Keeper_zh_TW.png")
var flag_uk = preload("res://systems/localization/Keeper_uk.png")
var flag_he = preload("res://systems/localization/Keeper_he.png")
var flag_cs = preload("res://systems/localization/Keeper_cs.png")
var flag_id = preload("res://systems/localization/Keeper_id.png")
var flag_ar = preload("res://systems/localization/Keeper_ar.png")
var flag_sr_Latn = preload("res://systems/localization/Keeper_latin.png")
var flag_hu = preload("res://systems/localization/Keeper_hu.png")

func _ready():
	set_keeper_language_flag()
	set_Language_button_text(TranslationServer.get_locale())
	
func set_Language_button_text(code):
	var language = Data.LanguageNamesByCode.get(code, code)
	find_node("LanguageSelectButton").text = language

func set_keeper_language_flag():
		match TranslationServer.get_locale():
			"ar_SA":
				$KeeperWithFlag.texture = flag_ar
			"bg_BG":
				$KeeperWithFlag.texture = flag_bg
			"cs_CZ":
				$KeeperWithFlag.texture = flag_cs
			"da_DK":
				$KeeperWithFlag.texture = flag_dk
			"de_DE":
				$KeeperWithFlag.texture = flag_de
			"en_US":
				$KeeperWithFlag.texture = flag_en
			"en_GB":
				$KeeperWithFlag.texture = flag_en
			"en":
				$KeeperWithFlag.texture = flag_en
			"es_ES":
				$KeeperWithFlag.texture = flag_es
			"es_AR":
				$KeeperWithFlag.texture = flag_es_LAT
			"fi_FI":
				$KeeperWithFlag.texture = flag_fi
			"fr_FR":
				$KeeperWithFlag.texture = flag_fr
			"he_IL":
				$KeeperWithFlag.texture = flag_he
			"hu_HU":
				$KeeperWithFlag.texture = flag_hu
			"id_ID":
				$KeeperWithFlag.texture = flag_id
			"it_IT":
				$KeeperWithFlag.texture = flag_it
			"ja_JP":
				$KeeperWithFlag.texture = flag_ja
			"ko_KR":
				$KeeperWithFlag.texture = flag_ko
			"nl_NL":
				$KeeperWithFlag.texture = flag_nl
			"nb_NO":
				$KeeperWithFlag.texture = flag_no
			"pl_PL":
				$KeeperWithFlag.texture = flag_pl
			"pt_BR":
				$KeeperWithFlag.texture = flag_pt_BR
			"pt_PT":
				$KeeperWithFlag.texture = flag_pt_PT
			"ru_RU":
				$KeeperWithFlag.texture = flag_ru
			"ro_RO":
				$KeeperWithFlag.texture = flag_ro
			"sv_SE":
				$KeeperWithFlag.texture = flag_sv
			"th_TH":
				$KeeperWithFlag.texture = flag_th
			"tr_TR":
				$KeeperWithFlag.texture = flag_tr
			"uk_UA":
				$KeeperWithFlag.texture = flag_uk
			"vi_VN":
				$KeeperWithFlag.texture = flag_vi
			"zh_CN":
				$KeeperWithFlag.texture = flag_zh
			"zh_TW":
				$KeeperWithFlag.texture = flag_zh_TW
	

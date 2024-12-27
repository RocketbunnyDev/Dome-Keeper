extends JsonSerializable
class_name GetPlayerCombinedInfoResultPayload


var AccountInfo: UserAccountInfo


var CharacterInventories: Array


var CharacterList: Array


var PlayerProfile


var PlayerStatistics: Array


var TitleData


var UserData


var UserDataVersion


var UserInventory: Array


var UserReadOnlyData


var UserReadOnlyDataVersion


var UserVirtualCurrency


var UserVirtualCurrencyRechargeTimes


func _get_type_for_property(property_name: String)->String:
	match property_name:
		"AccountInfo":
			return "UserAccountInfo"
	
	push_error("Could not find mapping for property: " + property_name)
	return ._get_type_for_property(property_name)

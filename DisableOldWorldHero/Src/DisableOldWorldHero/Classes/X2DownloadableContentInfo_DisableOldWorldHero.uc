//---------------------------------------------------------------------------------------
//  FILE:   XComDownloadableContentInfo_DisableOldWorldHero.uc                                    
//           
//	Use the X2DownloadableContentInfo class to specify unique mod behavior when the 
//  player creates a new campaign or loads a saved game.
//  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_DisableOldWorldHero extends X2DownloadableContentInfo;

/// <summary>
/// This method is run if the player loads a saved game that was created prior to this DLC / Mod being installed, and allows the 
/// DLC / Mod to perform custom processing in response. This will only be called once the first time a player loads a save that was
/// create without the content installed. Subsequent saves will record that the content was installed.
/// </summary>
static event OnLoadedSavedGame() {

}

/// <summary>
/// Called when the player starts a new campaign while this DLC / Mod is installed
/// </summary>
static event InstallNewCampaign(XComGameState StartState) {

	RestoreCharacter(StartState);

}

static function RestoreCharacter(XComGameState StartState) {

	local XComGameState_Unit BarracksUnit;
	local CharacterPoolManager CharacterPool;
	local XComGameState_HeadquartersXCom XComHQ;
	local StateObjectReference UnitRef;
	local XComGameStateHistory History;
	local XComGameState_Unit PoolUnit;
	local X2ItemTemplateManager ItemMgr;
	local X2EquipmentTemplate ArmorTemplate;
	local XComGameState_Item ResistanceArmor;
	local XComGameState_Item KevlarArmor;
	local X2CharacterTemplate CharTemplate;
	local TAppearance KevlarAppearance;

	XComHQ = `XCOMHQ;
	History = `XCOMHISTORY;

	foreach XComHQ.Crew(UnitRef) {

		BarracksUnit = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
		BarracksUnit = XComGameState_Unit(StartState.ModifyStateObject(class'XComGameState_Unit', BarracksUnit.ObjectID));

		if (BarracksUnit != none && BarracksUnit.IsSoldier() && DoesSoldierHaveOldWarHeroAppearance(BarracksUnit)) {

			`log("TEST - Old World Soldier Located");

			ResistanceArmor = BarracksUnit.GetItemInSlot(eInvSlot_Armor, StartState, true); // Get the Resistance Warrior Armor the Old World Hero is wearing.

			// Check if the unit has Resistance Warrior Kevlar Armor equipped, and if not, go to the next unit in the Crew array.
			// Failsafe in case the user has a Character Pool unit w/ the exact same appearance as the Old World Hero.
			if (ResistanceArmor == none || ResistanceArmor.GetMyTemplateName() != 'KevlarArmor_DLC_Day0') {

				continue;

			}

			CharTemplate = BarracksUnit.GetMyTemplate();
			if (CharTemplate == none) continue;

			CharacterPool = CharacterPoolManager(`XENGINE.GetCharacterPoolManager());
			PoolUnit = CharacterPool.GetCharacter(BarracksUnit.GetFullName());

			if (PoolUnit == none) { // If the Old World Hero doesn't override a Character Pool unit.

				`log("TEST - Character Pool Soldier Not Found");

				BarracksUnit.GetStoredAppearance(KevlarAppearance,, 'KevlarArmor'); // Gets the appearance of the Old World Hero when wearing standard Kevlar Armor.

				// Use stored appearance to modify appearance of Resistance Warrior Kevlar Armor to match that of standard Kevlar Armor.
				BarracksUnit.kAppearance.nmHaircut = KevlarAppearance.nmHaircut;
				BarracksUnit.kAppearance.nmHelmet = KevlarAppearance.nmHelmet;
				BarracksUnit.kAppearance.nmFacePropUpper = KevlarAppearance.nmFacePropUpper;
				BarracksUnit.kAppearance.nmFacePropLower = KevlarAppearance.nmFacePropLower;

				ResetTorso(BarracksUnit); // Reset Resistance Warrior Kevlar Armor to randomly choose new Torso and empty-out unused part-types.

				BarracksUnit.GenerateBackground(, BarracksUnit.kAppearance.nmFlag); //Regenerate Biography.

			} else { // If the Old World Hero does override a Character Pool unit.

				`log("TEST - Character Pool Soldier Located");

				// Modify appearance of Resistance Warrior Kevlar Armor to match that of the Character Pool unit.
				BarracksUnit.kAppearance.nmHaircut = PoolUnit.kAppearance.nmHaircut;
				BarracksUnit.kAppearance.nmHelmet = PoolUnit.kAppearance.nmHelmet;
				BarracksUnit.kAppearance.nmFacePropUpper = PoolUnit.kAppearance.nmFacePropUpper;
				BarracksUnit.kAppearance.nmFacePropLower = PoolUnit.kAppearance.nmFacePropLower;
				BarracksUnit.kAppearance.iAttitude = PoolUnit.kAppearance.iAttitude;

				ResetTorso(BarracksUnit); // Reset Resistance Warrior Kevlar Armor to randomly choose new Torso and empty-out unused part-types.

				BarracksUnit.SetBackground(PoolUnit.GetBackground()); // Gets Biography from Character Pool unit.

			}

			BarracksUnit.StoreAppearance(,'KevlarArmor_DLC_Day0'); // Store the now restored appearance of the Old World Hero w/ Resistance Warrior Kevlar Armor.

			// Replace their equipped Resistance Warrior Kevlar Armor with the armor stored in the unit's default loadout. 
			// In 99.9% of cases that's gonna be standard Kevlar Armor, but mods can change it pretty easily, so let's get the armor from the character template.
			ArmorTemplate = FindDefaultArmorForUnit(BarracksUnit);
			if (ArmorTemplate == none) {	

				// Fallback to standard Kevlar Armor if there's no specified armor template.
				ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
				ArmorTemplate = X2EquipmentTemplate(ItemMgr.FindItemTemplate('KevlarArmor'));

			}

			if (ArmorTemplate == none) return; // Exit function if there's not even Kevlar Armor, which shouldn't ever happen.
			
			KevlarArmor = ArmorTemplate.CreateInstanceFromTemplate(StartState); // Define Kevlar Armor Template

			// Remove and destroy the Resistance Warrior Kevlar Armor that was equipped.
			BarracksUnit.RemoveItemFromInventory(ResistanceArmor, StartState);
			StartState.RemoveStateObject(ResistanceArmor.ObjectID);

			// Equip standard Kevlar Armor.
			BarracksUnit.AddItemToInventory(KevlarArmor, eInvSlot_Armor, StartState);
			if (PoolUnit != none) BarracksUnit.kAppearance.iAttitude = PoolUnit.kAppearance.iAttitude; // Restore Attitude for overwritten Character Pool unit when wearing standard Kevlar Armor.
			BarracksUnit.StoreAppearance(,'KevlarArmor'); // Save unit's appearance w/ standard Kevlar Armor.

			// Exit function once we find the first soldier matching the condition.
			return;

		}
	}
}

static private function bool DoesSoldierHaveOldWarHeroAppearance(XComGameState_Unit UnitState) { //	Check if the unit has Aviators and Blowout hair.

	return ((UnitState.kAppearance.nmHaircut == 'Classic_M' || UnitState.kAppearance.nmHaircut == 'Classic_F') && 
			(UnitState.kAppearance.nmFacePropUpper == 'Aviators_M' || UnitState.kAppearance.nmFacePropUpper == 'Aviators_F'));

}

static private function X2EquipmentTemplate FindDefaultArmorForUnit(XComGameState_Unit UnitState) {

	local X2CharacterTemplate			CharTemplate;
	local X2ItemTemplateManager			ItemTemplateManager;
	local InventoryLoadout				Loadout;
	local InventoryLoadoutItem			LoadoutItem;
	local X2EquipmentTemplate			EquipmentTemplate;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	CharTemplate = UnitState.GetMyTemplate();

	foreach ItemTemplateManager.Loadouts(Loadout) {

		if (Loadout.LoadoutName == CharTemplate.DefaultLoadout)	{

			foreach Loadout.Items(LoadoutItem) {

				EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(LoadoutItem.Item));

				if (EquipmentTemplate != none && EquipmentTemplate.InventorySlot == eInvSlot_Armor) {

					return EquipmentTemplate;

				}
			}

			return none;

		}
	}

	return none;

}

static function ResetTorso(XComGameState_Unit BarracksUnit) {

	local array<name> TemplateNamesM;
	local array<name> TemplateNamesF;

	TemplateNamesM.addItem('DLC_0_ResistanceWarrior_A_M');
	TemplateNamesM.addItem('DLC_0_ResistanceWarrior_B_M');
	TemplateNamesM.addItem('DLC_0_ResistanceWarrior_C_M');
	TemplateNamesM.addItem('DLC_0_ResistanceWarrior_D_M');
	TemplateNamesM.addItem('DLC_0_ResistanceWarrior_E_M');

	TemplateNamesF.addItem('DLC_0_ResistanceWarrior_A_F');
	TemplateNamesF.addItem('DLC_0_ResistanceWarrior_B_F');
	TemplateNamesF.addItem('DLC_0_ResistanceWarrior_C_F');
	TemplateNamesF.addItem('DLC_0_ResistanceWarrior_D_F');
	TemplateNamesF.addItem('DLC_0_ResistanceWarrior_E_F');

	if (BarracksUnit.kAppearance.iGender == 1) {	

		BarracksUnit.kAppearance.nmTorso = TemplateNamesM[`SYNC_RAND_STATIC(TemplateNamesM.Length)];

	} else {

		BarracksUnit.kAppearance.nmTorso = TemplateNamesF[`SYNC_RAND_STATIC(TemplateNamesM.Length)];

	}
}
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
	local XGCharacterGenerator CharGen;
	local X2CharacterTemplate CharTemplate;
	local X2CharacterTemplateManager CharTemplateMgr;
	local TSoldier Soldier;

	XComHQ = `XCOMHQ;
	History = `XCOMHISTORY;

	foreach XComHQ.Crew(UnitRef) {

		BarracksUnit = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
		BarracksUnit = XComGameState_Unit(StartState.ModifyStateObject(class'XComGameState_Unit', BarracksUnit.ObjectID));

		if (BarracksUnit != none && BarracksUnit.IsSoldier()) {

			 if ((BarracksUnit.kAppearance.nmHaircut == 'Classic_M' || BarracksUnit.kAppearance.nmHaircut == 'Classic_F') && (BarracksUnit.kAppearance.nmFacePropUpper == 'Aviators_M' || BarracksUnit.kAppearance.nmFacePropUpper == 'Aviators_F') && (BarracksUnit.kAppearance.nmTorso == 'DLC_0_ResistanceWarrior_E_M' || BarracksUnit.kAppearance.nmTorso == 'DLC_0_ResistanceWarrior_E_F')) {
			 //if (BarracksUnit.kAppearance.nmHaircut == 'Classic_M' || BarracksUnit.kAppearance.nmHaircut == 'Classic_F') {

				`log("TEST - Old World Soldier Located");

				CharTemplateMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
				CharTemplate = CharTemplateMgr.FindCharacterTemplate('Soldier');
				CharGen = `XCOMGRI.Spawn(CharTemplate.CharacterGeneratorClass);

				CharacterPool = CharacterPoolManager(`XENGINE.GetCharacterPoolManager());
				PoolUnit = CharacterPool.GetCharacter(BarracksUnit.GetFullName());

				ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
				ArmorTemplate = X2EquipmentTemplate(ItemMgr.FindItemTemplate('KevlarArmor'));
				KevlarArmor = ArmorTemplate.CreateInstanceFromTemplate(StartState);

				//Define Resistance Warrior Armor using the Old World Hero and Equip standard Kevlar Armor:
				ResistanceArmor = BarracksUnit.GetItemInSlot(eInvSlot_Armor);
				BarracksUnit.AddItemToInventory(KevlarArmor, eInvSlot_Armor, StartState);

				if (PoolUnit == none) { //If the Old World Soldier doesn't override a Character Pool Unit

					`log("TEST - Character Pool Soldier Not Found");

					//Handle Restoration:
					Soldier = CharGen.CreateTSoldier(CharTemplate.DataName);
					BarracksUnit.SetTAppearance(Soldier.kAppearance);
					BarracksUnit.SetCharacterName(Soldier.strFirstName, Soldier.strLastName, Soldier.strNickName);
					BarracksUnit.SetCountry(Soldier.nmCountry);
					BarracksUnit.GenerateBackground(, CharGen.BioCountryName);

					//Store appearance of Soldier w/ standard Kevlar Armor, then Equips Resistance Warrior Armor:
					BarracksUnit.StoreAppearance(,'KevlarArmor');
					BarracksUnit.AddItemToInventory(ResistanceArmor, eInvSlot_Armor, StartState);

					BarracksUnit.SetTAppearance(Soldier.kAppearance); //Set appearance of Soldier w/ Resistance Warrior Armor (Since parts of appearances are on a per-armor basis)

					BarracksUnit.StoreAppearance(,'KevlarArmor_DLC_Day0'); //Store appearance of Soldier w/ Resistance Warrior Armor

					ResetTorso(BarracksUnit); //Reset Resistance Warrior Armor to randomly choose new Torso and empty-out unused part-types

					BarracksUnit.RemoveItemFromInventory(ResistanceArmor, StartState);
					BarracksUnit.AddItemToInventory(KevlarArmor, eInvSlot_Armor, StartState); //Re-equip standard Kevlar Armor
					//BarracksUnit.RemoveItemFromInventory(ResistanceArmor, StartState); //Removes unused Resistance Armour so it isn't stuck in limbo

					if( CharGen != none ) {

						CharGen.Destroy();

					}

				} else { //If the Old World Soldier does override a Character Pool Unit

					`log("TEST - Character Pool Soldier Located");

					//Handle Restoration:
					BarracksUnit.SetBackground(PoolUnit.GetBackground());
					BarracksUnit.kAppearance = PoolUnit.kAppearance;

					BarracksUnit.kAppearance.iAttitude = PoolUnit.kAppearance.iAttitude;

					//Store appearance of Soldier w/ standard Kevlar Armor, then Equips Resistance Warrior Armor:
					BarracksUnit.StoreAppearance(,'KevlarArmor');
					BarracksUnit.AddItemToInventory(ResistanceArmor, eInvSlot_Armor, StartState);

					BarracksUnit.SetTAppearance(PoolUnit.kAppearance); //Set appearance of Soldier w/ Resistance Warrior Armor (Since parts of appearances are on a per-armor basis)

					BarracksUnit.StoreAppearance(,'KevlarArmor_DLC_Day0'); //Store appearance of Soldier w/ Resistance Warrior Armor

					ResetTorso(BarracksUnit); //Reset Resistance Warrior Armor to randomly choose new Torso and empty-out unused part-types

					BarracksUnit.RemoveItemFromInventory(ResistanceArmor, StartState);
					BarracksUnit.AddItemToInventory(KevlarArmor, eInvSlot_Armor, StartState); //Re-equip standard Kevlar Armor
					//BarracksUnit.RemoveItemFromInventory(ResistanceArmor, StartState); //Removes unused Resistance Armour so it isn't stuck in limbo

				}
			}
		}
	}    
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

	BarracksUnit.kAppearance.nmArms = '';
	BarracksUnit.kAppearance.nmLegs = '';
	BarracksUnit.kAppearance.nmLeftArm = '';		
	BarracksUnit.kAppearance.nmRightArm = '';	
	BarracksUnit.kAppearance.nmLeftArmDeco = '';	
	BarracksUnit.kAppearance.nmRightArmDeco = '';
	BarracksUnit.kAppearance.nmLeftForearm = '';
	BarracksUnit.kAppearance.nmRightForearm = '';
	BarracksUnit.kAppearance.nmThighs = '';
	BarracksUnit.kAppearance.nmShins = '';
	BarracksUnit.kAppearance.nmTorsoDeco = '';

}
local F={}
assert(loadfile('source/HunterToolsClassic/PetBrowserData.lua'))('test',F)
assert(loadfile('source/HunterToolsClassic/PetDatabase.lua'))('test',F)
assert(loadfile('source/HunterToolsClassic/ClassicReference.lua'))('test',F)
local byName={};local count=0
for _,ability in ipairs(F.petBrowserAbilities) do
    byName[ability.name]=ability
    for _,rank in ipairs(ability.ranks) do
        assert(rank.spellID<100000 and rank.petLevel<=60,'Forever spell leaked into Classic data')
        count=count+1
    end
end
assert(byName.Screech and not byName['Sonic Blast'] and not byName['Dismember'])
assert(byName.Bite.ranks[2].petLevel==8)
assert(F.petFamilyDiets.Owl=='Meat' and not F.petFamilyDiets.Fox)
assert(F.classicCreatures[3099] and F.classicCreatures[3099].zone=='Durotar')
assert(F.petCreatureDB[3099].abilities:find('Charge 1',1,true))
assert(not F.foreverPetCreatureDB and not F.petopiaForeverCreatures)
print('PASS: Era-specific ability ranks, families, teaching identities and search locations; '..count..' ranks')

assert(F.classicFamilies.Cat.source=='https://www.wow-petopia.com/classic/family.php?id=cat')
assert(F.classicFamilies.Owl.source=='https://www.wow-petopia.com/classic/family.php?id=owl')
assert(F.classicFamilies.Cat.diet=='Fish, Meat')
assert(table.concat(F.classicFamilies.Owl.learnable,', '):find('Screech',1,true))

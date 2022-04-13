-- Isolated Specs Loader
local IsolatedSpecifications = table.deepishCopy(CreatureObjectTemplate.Specifications) do
	IsolatedSpecifications.Attributes = nil::any;
	IsolatedSpecifications.MainInfo.Size.Tier = nil::any;
	IsolatedSpecifications.MainInfo.Size.MinutesToGrow = nil::any;
end
-- Base Types
export type Flags = typeof(CreatureObjectTemplate.Specifications.Attributes)
export type SoundInfo = typeof(DEFAULT_SOUND)
export type AnimationConfiguration = typeof(CreatureObjectTemplate.CreatureVisuals.Animations.Settings)
export type LandAnimations = typeof(CreatureObjectTemplate.CreatureVisuals.Animations.Land)
export type AerialAnimations = typeof(CreatureObjectTemplate.CreatureVisuals.Animations.Aerial)
export type AquaticAnimations = typeof(CreatureObjectTemplate.CreatureVisuals.Animations.Aquatic)
export type ActionAnimations = typeof(CreatureObjectTemplate.CreatureVisuals.Animations.Actions)
export type CreaturePalette = typeof(DEFAULT_PALETTE)
export type CreatureSpecs = typeof(CreatureObjectTemplate.Specifications)
-- Procedurally Generated Types
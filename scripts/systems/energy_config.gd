extends Resource

class_name EnergyConfig

## Centralized energy balance configuration
## Designer-tweakable values used by Eagle, Fish, and Nest

@export_group("Energy Capacity")
@export var initial_max_energy: float = 100.0
@export var energy_gain_per_nest_fed: float = 20.0
@export var energy_loss_per_nest_miss: float = 15.0

@export_group("Energy Drain & Costs")
@export var energy_loss_per_second: float = 1.0
@export var energy_loss_per_flap: float = 3.0
@export var hit_energy_loss: float = 20.0

@export_group("Fish")
@export var fish_energy_value: float = 25.0

@export_group("UI Thresholds")
@export var low_energy_threshold_percent: float = 0.2



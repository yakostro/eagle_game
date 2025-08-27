## Z-Order Constants for "The Last Eagle"
## Centralized z-index and layer management system
## Use these constants throughout the project for consistent layering

class_name ZOrder

# ===========================================
# NODE2D Z-INDEX VALUES (for 2D scene elements)
# ===========================================
# Lower values = farther back, Higher values = closer to camera

# PARALLAX BACKGROUND LAYERS (-40 to -20) - matches parallax_background_system.gd
const PARALLAX_GRADIENT: int = -40      # Gradient layer (furthest back sky/atmosphere)
const PARALLAX_MOUNTAINS: int = -30     # Mountain layer (distant mountains/terrain)
const PARALLAX_MIDDLE: int = -20        # Middle layer (mid-distance elements)


# OBSTACLE LAYERS (-5 to -2)
const FLOATING_ISLANDS: int = -5
const STALACTITES: int = -4
const OBSTACLE_SPAWNERS: int = -3
const MOUNTAINS: int = -2


# GAMEPLAY LAYERS (0 to 19)
const FISH: int = 0                    # Fish (same layer as player)
const PLAYER: int = 1                  # Eagle        
const ENEMIES: int = 2                 # Enemy birds
const PROJECTILES: int = 3             # Any projectiles or attacks


# ENVIRONMENT LAYERS (-1)
const WIND_PARTICLES: int = 10

# ===========================================
# CANVAS LAYER VALUES (for UI and overlays)
# ===========================================
# Lower values = behind UI, Higher values = in front

# BACKGROUND UI (-10 to -1)
const UI_BACKGROUND: int = -5

# GAME UI (0 to 50)
const UI_GAME_DEFAULT: int = 0
const UI_HEALTH_ENERGY: int = 10       # Energy/Morale bars
const UI_GAME_HUD: int = 15           # Score, mini-map, etc.
const UI_GAME_NOTIFICATIONS: int = 20  # "Nest ahead!", morale pops

# MENU UI (50 to 100)
const UI_MAIN_MENU: int = 50
const UI_PAUSE_MENU: int = 60
const UI_SETTINGS: int = 70

# OVERLAY UI (100 to 500)
const UI_MODAL_DIALOGS: int = 100
const UI_LOADING_SCREEN: int = 200
const UI_FADE_OVERLAY: int = 300

# POST-PROCESSING (500+)
const POST_PROCESSING_SHADERS: int = 500
const UI_DEBUG_OVERLAY: int = 900      # Debug information
const UI_TRANSITION_OVERLAY: int = 1000 # Scene transitions (highest)


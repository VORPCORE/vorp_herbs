Config = {}

Config.MinimumDistance = 2.0 -- Minimum distance required to enable prompts for digging and picking up reward item

Config.Timeout = 2           -- Timeout (in minutes)

-- Pre-spawned plants to check for. Leave blank to not have any prompts spawn on world objects.
Config.Plants = {
    {                                               -- Follow this format exactly when adding in new world plants
        hash = joaat("s_inv_blackberry01x"),        -- Plant name as a hash value
        name = "Blackberry",                        -- Plant name to be displayed in prompt
        reward = "blackberry",                      -- Plant db reward item
        minReward = 1,                              -- Minimum reward per plant (optional, defaults to 1!)
        maxReward = 5                               -- Maximum reward per plant (optional, defaults to 1!)
    },
    { 
        hash = joaat("s_indiantobacco01x"),
        name = "Indian Tobbaco",
        reward = "Indian_Tobbaco",
        minReward = 1, 
        maxReward = 5
    },
        {                                      
        hash = joaat("p_tree_apple_01"),       
        name = "Apple",                     
        reward = "apple",                   
        minReward = 1,                          
        maxReward = 5                              
    },
        },
        {                                              
        hash = joaat("crp_tobaccoplant_ac_sim"),        
        name = "Guarma Tobacco",                        
        reward = "Guarma_Tobacco",                      
        minReward = 1,                             
        maxReward = 5                             
    },
     },
        { 
        hash = joaat("crp_wheat_dry_aa_sim"),
        name = "Grain",
        reward = "Grain",
        minReward = 1,
        maxReward = 5  
    },
        {                                             
        hash = joaat("rdr_bush_agave_aa_sim"),       
        name = "Agave",                        
        reward = "rdr_bush_agave_aa_sim",                     
        minReward = 1,                              
        maxReward = 5                             
    },
}

-- Default locations. Feel free to add more, just follow the existing template. Leave blank to not have any plants or prompts spawn.
Config.Locations = {
    -- Fully customized node (spawns in custom objects via coords)
    {
        name = "Tobacco Plant",                     -- Area name
        reward = "Indian_Tobbaco",                  -- Reward item database name
        plantModel = "s_indiantobacco01x",          -- Plant model to spawn (optional!)
        coords = vector3(2018.05, -880.44, 42.54),  -- Coordinates for plant model object
        timeout = 1,                                -- Custom timeout per node (optional, in minutes!)
        minReward = 1,                              -- Minimum reward per plant (optional, defaults to 1!)
        maxReward = 5                               -- Maximum reward per plant (optional, defaults to 1!)
    },
    -- Partially customized node (uses coords to create prompt, preferrably near existing world objects)
    {
        name = "Orange Tree",                        -- Area name
        reward = "orange",                           -- Reward item database name
        coords = vector3(1999.49, -883.85, 42.78) -- Coordinates for dirt mounds/reward item objects
    }
}

-- Language text for prompts
Config.Language = {
    PromptText = "Pick",
    PromptGroupName = "Plants"
}

-- Control actions for prompts
Config.ControlAction = 0x6D1319BE -- R key
